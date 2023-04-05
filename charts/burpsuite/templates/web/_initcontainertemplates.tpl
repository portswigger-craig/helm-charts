{{- define "burpsuite.web.initContainerTemplates" -}}
- name: init-web-server-keystore
  image: {{ include "burpsuite.web.image" . }}
  resources:
    limits:
      cpu:
      memory:
    requests:
      cpu:
      memory:
  envFrom:
    - configMapRef:
        name: {{ include "burpsuite.web.fullname" . }}
    - secretRef:
        name: {{ include "burpsuite.web.fullname" . }}
  command:
    - 'sh'
    - '-c'
    - |
      set -eux

      mkdir -p /home/burpsuite/keystores
      mkdir -p /home/burpsuite/logs
      mkdir -p /home/burpsuite/burp

      /usr/local/burpsuite_enterprise/bin/createKeystore webserver $BSEE_CLIENT_KEYSTORE_LOCATION $BSEE_CLIENT_KEYSTORE_PASSWORD
  volumeMounts:
    - name: home-burpsuite
      mountPath: /home/burpsuite
  securityContext:
    {{- toYaml .Values.web.securityContext | nindent 4 }}
{{- end -}}