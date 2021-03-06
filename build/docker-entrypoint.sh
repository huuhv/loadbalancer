#!/usr/bin/env bash

set -Eeo pipefail
APP_HOME=/var/www/html
cd ${APP_HOME}

_log() {
  echo "[Entrypoint]: $*" >&2
}

get_latest_commit() {
  GIT_COMMIT_ID=$(git rev-parse HEAD)
  echo "GIT_COMMIT_ID=${GIT_COMMIT_ID}" >> ${APP_HOME}/.env
  _log "Latest git commit ID: ${GIT_COMMIT_ID}"
}

_artisan() {
  _log "php artisan $*"
  php artisan "$@"
}

_query() {
  _log "query: $*"
  mysql -h ${DB_HOST} -u${DB_USERNAME} -p${DB_PASSWORD} ${DB_DATABASE} -N -B -e "$*"
}

_wait() {
  until _query "select version()" > /dev/null 2>&1; do
    _log "waiting for mysql service"
    sleep 1;
  done
}

app_key() {
  local result=$(_artisan key:generate --force --show)
  echo "APP_KEY=${result}" >> ${APP_HOME}/.env
}

config() {
  _artisan config:clear
}

seeder() {
  local result=$(_query "SELECT email FROM users WHERE email = 'admin@example.com'")
  # _log "${result}"
  if [ -z "${result}" ]; then
    _artisan db:seed --class UserSeeder --force
  fi
}

migrate() {
  # must be force option in production mode
  _artisan migrate --force
}

httpd() {
  local httpd_conf=/etc/httpd/conf.d
  sed -i -e "s/\$DOMAIN/${DOMAIN}/" ${httpd_conf}/loadbalancing.conf
  sed -i "s/\$CONTAINER_ID/${container_id}/" ${httpd_conf}/loadbalancing.conf
  sed -i "s|#ServerName www\.example\.com:80|ServerName $HOSTNAME:80|g" /etc/httpd/conf/httpd.conf
}

set_container_id() {
  container_id=`cat /etc/hostname`
  _log "container_id: $container_id"
  echo "CONTAINER_ID=${container_id}" >> ${APP_HOME}/.env
}

main() {
  # clear env
  true > ${APP_HOME}/.env
  set_container_id
  httpd
  app_key
  _wait
  config
  migrate
  seeder
  get_latest_commit
  _log "exec: $@"
  exec "$@"
}

main $@
