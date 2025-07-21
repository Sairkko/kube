{{/*
Expand the name of the chart.
*/}}
{{- define "orocommerce.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "orocommerce.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "orocommerce.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "orocommerce.labels" -}}
helm.sh/chart: {{ include "orocommerce.chart" . }}
{{ include "orocommerce.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "orocommerce.selectorLabels" -}}
app.kubernetes.io/name: {{ include "orocommerce.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Frontend labels
*/}}
{{- define "orocommerce.frontend.labels" -}}
{{ include "orocommerce.labels" . }}
app.kubernetes.io/component: frontend
{{- end }}

{{/*
Frontend selector labels
*/}}
{{- define "orocommerce.frontend.selectorLabels" -}}
{{ include "orocommerce.selectorLabels" . }}
app.kubernetes.io/component: frontend
{{- end }}

{{/*
Backend labels
*/}}
{{- define "orocommerce.backend.labels" -}}
{{ include "orocommerce.labels" . }}
app.kubernetes.io/component: backend
{{- end }}

{{/*
Backend selector labels
*/}}
{{- define "orocommerce.backend.selectorLabels" -}}
{{ include "orocommerce.selectorLabels" . }}
app.kubernetes.io/component: backend
{{- end }}

{{/*
Workers labels
*/}}
{{- define "orocommerce.workers.labels" -}}
{{ include "orocommerce.labels" . }}
app.kubernetes.io/component: workers
{{- end }}

{{/*
Workers selector labels
*/}}
{{- define "orocommerce.workers.selectorLabels" -}}
{{ include "orocommerce.selectorLabels" . }}
app.kubernetes.io/component: workers
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "orocommerce.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "orocommerce.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create the name of the frontend service account to use
*/}}
{{- define "orocommerce.frontend.serviceAccountName" -}}
{{- if .Values.frontend.serviceAccount.create }}
{{- default (printf "%s-frontend" (include "orocommerce.fullname" .)) .Values.frontend.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.frontend.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create the name of the backend service account to use
*/}}
{{- define "orocommerce.backend.serviceAccountName" -}}
{{- if .Values.backend.serviceAccount.create }}
{{- default (printf "%s-backend" (include "orocommerce.fullname" .)) .Values.backend.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.backend.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
PostgreSQL hostname
*/}}
{{- define "orocommerce.postgresql.hostname" -}}
{{- if .Values.postgresql.enabled }}
{{- printf "%s-postgresql" (include "orocommerce.fullname" .) }}
{{- else }}
{{- "postgresql-external" }}
{{- end }}
{{- end }}

{{/*
Redis hostname
*/}}
{{- define "orocommerce.redis.hostname" -}}
{{- if .Values.redis.enabled }}
{{- printf "%s-redis-master" (include "orocommerce.fullname" .) }}
{{- else }}
{{- "redis-external" }}
{{- end }}
{{- end }}

{{/*
Elasticsearch hostname
*/}}
{{- define "orocommerce.elasticsearch.hostname" -}}
{{- if .Values.elasticsearch.enabled }}
{{- printf "%s-elasticsearch" (include "orocommerce.fullname" .) }}
{{- else }}
{{- "elasticsearch-external" }}
{{- end }}
{{- end }}

{{/*
Create nginx configuration
*/}}
{{- define "orocommerce.nginx.config" -}}
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;

events {
    worker_connections 1024;
    use epoll;
    multi_accept on;
}

http {
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;

    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    client_max_body_size 100M;

    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    # Compression
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/javascript
        application/xml+rss
        application/json;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;

    upstream backend {
        least_conn;
        server {{ include "orocommerce.fullname" . }}-backend:{{ .Values.backend.service.port }};
    }

    server {
        listen 80;
        server_name {{ .Values.global.domain }};
        root /var/www/html/public;
        index index.php;

        # Health check
        location /health {
            return 200 "OK";
            add_header Content-Type text/plain;
        }

        # Static files
        location ~* \.(jpg|jpeg|png|gif|ico|css|js|pdf|txt|tar|gz)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
            try_files $uri @backend;
        }

        # PHP files
        location ~ \.php$ {
            try_files $uri @backend;
        }

        # Default location
        location / {
            try_files $uri @backend;
        }

        # Proxy to backend
        location @backend {
            proxy_pass http://backend;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_connect_timeout 30;
            proxy_send_timeout 30;
            proxy_read_timeout 30;
            proxy_buffering on;
            proxy_buffer_size 4k;
            proxy_buffers 8 4k;
        }

        # Deny access to sensitive files
        location ~ /\. {
            deny all;
        }

        location ~ /(var|src|bin|tests|vendor)/ {
            deny all;
        }
    }
}
{{- end }}

{{/*
Create PHP-FPM configuration
*/}}
{{- define "orocommerce.php.config" -}}
[global]
daemonize = no
error_log = /proc/self/fd/2

[www]
user = www-data
group = www-data
listen = 0.0.0.0:9000
listen.owner = www-data
listen.group = www-data
listen.mode = 0660

pm = dynamic
pm.max_children = 20
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 3

catch_workers_output = yes
clear_env = no

access.log = /proc/self/fd/2
access.format = "%R - %u %t \"%m %r%Q%q\" %s %f %{mili}d %{kilo}M %C%%"

; Security
security.limit_extensions = .php
{{- end }}

{{/*
Create application environment variables
*/}}
{{- define "orocommerce.env" -}}
- name: ORO_APP_DOMAIN
  value: {{ .Values.global.domain | quote }}
- name: ORO_DB_HOST
  value: {{ include "orocommerce.postgresql.hostname" . | quote }}
- name: ORO_DB_NAME
  value: {{ .Values.postgresql.auth.database | quote }}
- name: ORO_DB_USER
  value: {{ .Values.postgresql.auth.username | quote }}
- name: ORO_DB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ include "orocommerce.fullname" . }}-postgresql
      key: postgres-password
- name: ORO_REDIS_HOST
  value: {{ include "orocommerce.redis.hostname" . | quote }}
- name: ORO_REDIS_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ include "orocommerce.fullname" . }}-redis
      key: redis-password
- name: ORO_ELASTICSEARCH_HOST
  value: {{ include "orocommerce.elasticsearch.hostname" . | quote }}
- name: ORO_ELASTICSEARCH_PORT
  value: "9200"
- name: APP_ENV
  value: "prod"
- name: SYMFONY_ENV
  value: "prod"
{{- range .Values.backend.env }}
- name: {{ .name }}
  value: {{ .value | quote }}
{{- end }}
{{- range .Values.backend.secrets }}
- name: {{ .name }}
  valueFrom:
    secretKeyRef:
      name: {{ .secret }}
      key: {{ .key }}
{{- end }}
{{- end }}

{{/*
Create security context
*/}}
{{- define "orocommerce.securityContext" -}}
{{- if .Values.podSecurityPolicy.enabled }}
securityContext:
  runAsNonRoot: {{ .Values.podSecurityPolicy.runAsNonRoot }}
  runAsUser: {{ .Values.podSecurityPolicy.runAsUser }}
  fsGroup: {{ .Values.podSecurityPolicy.fsGroup }}
  allowPrivilegeEscalation: {{ .Values.podSecurityPolicy.allowPrivilegeEscalation }}
{{- end }}
{{- end }}

{{/*
Create resource limits
*/}}
{{- define "orocommerce.resources" -}}
{{- if .resources }}
resources:
  {{- toYaml .resources | nindent 2 }}
{{- end }}
{{- end }}

{{/*
Create node selector
*/}}
{{- define "orocommerce.nodeSelector" -}}
{{- if .nodeSelector }}
nodeSelector:
  {{- toYaml .nodeSelector | nindent 2 }}
{{- end }}
{{- end }}

{{/*
Create tolerations
*/}}
{{- define "orocommerce.tolerations" -}}
{{- if .tolerations }}
tolerations:
  {{- toYaml .tolerations | nindent 2 }}
{{- end }}
{{- end }}

{{/*
Create affinity
*/}}
{{- define "orocommerce.affinity" -}}
{{- if .affinity }}
affinity:
  {{- toYaml .affinity | nindent 2 }}
{{- end }}
{{- end }} 