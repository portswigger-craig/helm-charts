{{- define "burpsuite.podTemplate" -}}
metadata:
  annotations:
    checksum/enterprise-env-configmap: {{ $entEnvCm := include (print $.Template.BasePath "/enterprise/env-configmap.yaml") . | fromYaml }}{{ $entEnvCm.data | toYaml | sha256sum }}
    checksum/enterprise-env-secret: {{ $entEnvSec := include (print $.Template.BasePath "/enterprise/env-secret.yaml") . | fromYaml }}{{ $entEnvSec.data | toYaml | sha256sum }}
    checksum/web-env-configmap: {{ $webEnvCm := include (print $.Template.BasePath "/web/env-configmap.yaml") . | fromYaml }}{{ $webEnvCm.data | toYaml | sha256sum }}
    checksum/web-env-secret: {{ $webEnvSec := include (print $.Template.BasePath "/web/env-secret.yaml") . | fromYaml }}{{ $webEnvSec.data | toYaml | sha256sum }}
  {{- with .Values.pod.annotations }}
  {{- toYaml . | nindent 4 }}
  {{- end }}
  labels:
  {{- include "burpsuite.pod.labels" . | nindent 4 }}
  {{- with .Values.pod.labels }}
  {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  dnsConfig:
    options:
      - name: ndots
        value: "1"
  {{- with .Values.pod.imagePullSecrets }}
  imagePullSecrets:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  serviceAccountName: {{ include "burpsuite.serviceAccountName" . }}
  terminationGracePeriodSeconds: 10
  securityContext:
    runAsUser: 42877
    fsGroup: 42877
  initContainers:
    {{- include "burpsuite.enterprise.initContainerTemplates" . | nindent 4 }}
    {{- include "burpsuite.web.initContainerTemplates" . | nindent 4 }}
  containers:
    {{- if .Values.database.useEmbedded -}}
    {{- include "burpsuite.database.containerTemplate" . | nindent 4 }}
    {{- end -}}
    {{- include "burpsuite.enterprise.containerTemplate" . | nindent 4 }}
    {{- include "burpsuite.web.containerTemplate" . | nindent 4 }}
  {{- with .Values.pod.affinity }}
  affinity:
    {{- tpl (toYaml .Values.pod.affinity) . | nindent 4 }}
  {{- end }}
  {{- with .Values.pod.nodeSelector }}
  nodeSelector:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with .Values.pod.tolerations }}
  tolerations:
  {{- toYaml . | nindent 2 }}
  {{- end }}
  {{- if .Values.topologySpreadConstraints }}
  topologySpreadConstraints:
    {{- tpl (toYaml .Values.topologySpreadConstraints) . | nindent 4 }}
  {{- end }}
  volumes:
  - name: home-burpsuite
    emptyDir:
      sizeLimit: 2Gi
  - name: tmp
    emptyDir:
      sizeLimit: 1Gi
  {{- if .Values.database.useEmbedded }}
  - name: database-vol
    secret:
      secretName: database-vol
  {{- end }}
{{- end }}