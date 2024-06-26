{{/*
Expand the name of the chart.
*/}}
{{- define "burpsuite.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified web app name.
*/}}
{{- define "burpsuite.web.fullname" -}}
{{- $name := include "burpsuite.fullname" . | trunc 59 | trimSuffix "-" }}
{{- printf "%s-web" $name }}
{{- end }}

{{/*
Create a default fully qualified enterprise app name.
*/}}
{{- define "burpsuite.enterprise.fullname" -}}
{{- $name := include "burpsuite.fullname" . | trunc 52 | trimSuffix "-" }}
{{- printf "%s-enterprise" $name }}
{{- end }}

{{- define "burpsuite.enterprise.version" -}}
{{- coalesce .Values.enterprise.image.tag .Values.global.image.tag .Chart.AppVersion }}
{{- end -}}

{{- define "burpsuite.enterprise.image" -}}
{{- if .Values.enterprise.image.sha256 -}}
{{- printf "%s/%s:%s@sha256:%s" (.Values.enterprise.image.registry | default .Values.global.image.registry) .Values.enterprise.image.repository (include "burpsuite.enterprise.version" .) (trimPrefix "sha256:" .Values.enterprise.image.sha256) }}
{{- else -}}
{{- printf "%s/%s:%s" (.Values.enterprise.image.registry | default .Values.global.image.registry) .Values.enterprise.image.repository (include "burpsuite.enterprise.version" .) }}
{{- end -}}
{{- end -}}

{{- define "burpsuite.web.version" -}}
{{- coalesce .Values.web.image.tag .Values.global.image.tag .Chart.AppVersion }}
{{- end -}}

{{- define "burpsuite.web.image" -}}
{{- if .Values.web.image.sha256 -}}
{{- printf "%s/%s:%s@sha256:%s" (.Values.web.image.registry | default .Values.global.image.registry) .Values.web.image.repository (include "burpsuite.web.version" .) (trimPrefix "sha256:" .Values.web.image.sha256) }}
{{- else -}}
{{- printf "%s/%s:%s" (.Values.web.image.registry | default .Values.global.image.registry) .Values.web.image.repository (include "burpsuite.web.version" .) }}
{{- end -}}
{{- end -}}

{{- define "burpsuite.agent.version" -}}
{{- coalesce .Values.agent.image.tag .Values.global.image.tag .Chart.AppVersion }}
{{- end -}}

{{- define "burpsuite.agent.image" -}}
{{- printf "%s/%s:%s" (.Values.agent.image.registry | default .Values.global.image.registry) .Values.agent.image.repository (include "burpsuite.agent.version" .) }}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "burpsuite.fullname" -}}
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
{{- define "burpsuite.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "burpsuite.labels" -}}
helm.sh/chart: {{ include "burpsuite.chart" . }}
{{ include "burpsuite.selectorLabels" . }}
app.kubernetes.io/version: {{ (include "burpsuite.enterprise.version" .) | replace "+" "_" | trunc 63 | trimSuffix "-" | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "burpsuite.selectorLabels" -}}
app.kubernetes.io/name: {{ include "burpsuite.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Pod labels
*/}}
{{- define "burpsuite.pod.labels" -}}
{{ include "burpsuite.selectorLabels" . }}
app.kubernetes.io/version: {{ (include "burpsuite.enterprise.version" .) | replace "+" "_" | trunc 63 | trimSuffix "-" | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "burpsuite.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "burpsuite.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Fetch given field from existing enterprise secret or generate a new random value
*/}}
{{- define "burpsuite.enterprise.fetchOrCreateSecretField" -}}
{{- $context := index . 0 -}}
{{- $secretFieldName := index . 1 -}}

{{- $secretObj := (lookup "v1" "Secret" $context.Release.Namespace  "enterprise-env") | default dict }}
{{- $secretData := (get $secretObj "data") | default dict }}
{{- $secretFieldValue := (get $secretData $secretFieldName) | default (randAlphaNum 30 | b64enc) }}
{{- $secretFieldValue -}}
{{- end -}}

{{- define "burpsuite.enterprise.secretValue" -}}
{{- $context := index . 0 -}}
{{- $suppliedValue := index . 1 -}}
{{- $secretFieldName := index . 2 -}}
{{- if $suppliedValue -}}
{{ $suppliedValue | b64enc }}
{{- else -}}
{{ include "burpsuite.enterprise.fetchOrCreateSecretField"  (list $context $secretFieldName) }}
{{- end -}}
{{- end -}}

{{/*
Fetch given field from existing web secret or generate a new random value
*/}}
{{- define "burpsuite.web.fetchOrCreateSecretField" -}}
{{- $context := index . 0 -}}
{{- $secretFieldName := index . 1 -}}

{{- $secretObj := (lookup "v1" "Secret" $context.Release.Namespace  "web-env") | default dict }}
{{- $secretData := (get $secretObj "data") | default dict }}
{{- $secretFieldValue := (get $secretData $secretFieldName) | default (randAlphaNum 30 | b64enc) }}
{{- $secretFieldValue -}}
{{- end -}}

{{- define "burpsuite.web.secretValue" -}}
{{- $context := index . 0 -}}
{{- $suppliedValue := index . 1 -}}
{{- $secretFieldName := index . 2 -}}
{{- if $suppliedValue -}}
{{ $suppliedValue | b64enc }}
{{- else -}}
{{ include "burpsuite.web.fetchOrCreateSecretField"  (list $context $secretFieldName) }}
{{- end -}}
{{- end -}}

{{/*
Fetch given field from existing enterprise secret or generate a new random value
*/}}
{{- define "burpsuite.database.fetchOrCreateSecretField" -}}
{{- $context := index . 0 -}}
{{- $secretFieldName := index . 1 -}}

{{- $secretObj := (lookup "v1" "Secret" $context.Release.Namespace  "database-env") | default dict }}
{{- $secretData := (get $secretObj "data") | default dict }}
{{- $secretFieldValue := (get $secretData $secretFieldName) | default (randAlphaNum 30 | b64enc) }}
{{- $secretFieldValue -}}
{{- end -}}

{{- define "burpsuite.database.secretValue" -}}
{{- $context := index . 0 -}}
{{- $suppliedValue := index . 1 -}}
{{- $secretFieldName := index . 2 -}}
{{- if $suppliedValue -}}
{{ $suppliedValue | b64enc }}
{{- else -}}
{{ include "burpsuite.database.fetchOrCreateSecretField"  (list $context $secretFieldName) }}
{{- end -}}
{{- end -}}

{{- define "burpsuite.database.image" -}}
{{- if .Values.database.image.sha256 -}}
{{- printf "%s/%s:%s@sha256:%s" (.Values.database.image.registry | default .Values.global.image.registry) .Values.database.image.repository .Values.database.image.tag (trimPrefix "sha256:" .Values.database.image.sha256) }}
{{- else -}}
{{- printf "%s/%s:%s" (.Values.database.image.registry | default .Values.global.image.registry) .Values.database.image.repository .Values.database.image.tag }}
{{- end -}}
{{- end -}}

{{- define "burpsuite.database.init" -}}
{{- $enterpriseUserPassword := include "burpsuite.enterprise.secretValue" (list . .Values.database.users.enterprise.password "BSEE_ADMIN_REPOSITORY_PASSWORD") -}}
{{- $scannerUserPassword := include "burpsuite.enterprise.secretValue" (list . .Values.database.users.scanner.password "BSEE_AGENT_REPOSITORY_PASSWORD") }}
CREATE USER {{ .Values.database.users.enterprise.username }} PASSWORD '{{ $enterpriseUserPassword }}';
CREATE USER {{ .Values.database.users.scanner.username }} PASSWORD '{{ $scannerUserPassword }}';

CREATE DATABASE burp_enterprise;
ALTER DATABASE burp_enterprise OWNER TO {{ .Values.database.users.enterprise.username }};
GRANT ALL ON DATABASE burp_enterprise TO {{ .Values.database.users.enterprise.username }};

\c burp_enterprise

CREATE SCHEMA burp_enterprise AUTHORIZATION {{ .Values.database.users.enterprise.username }};
GRANT USAGE ON SCHEMA burp_enterprise TO {{ .Values.database.users.scanner.username }};
ALTER USER {{ .Values.database.users.scanner.username }} SET search_path = "burp_enterprise";
{{- end -}}

{{- define "burpsuite.database.url" -}}
{{- if .Values.database.useEmbedded -}}
jdbc:postgresql://localhost:5432/burp_enterprise
{{- else -}}
{{ .Values.database.externalUrl }}
{{- end -}}
{{- end -}}

{{/*
Renders a value that contains template.
Usage:
{{ include "burpsuite.tplvalues.render" ( dict "value" .Values.path.to.the.Value "context" $) }}
*/}}
{{- define "burpsuite.tplvalues.render" -}}
    {{- if typeIs "string" .value }}
        {{- tpl .value .context }}
    {{- else }}
        {{- tpl (.value | toYaml) .context }}
    {{- end }}
{{- end -}}