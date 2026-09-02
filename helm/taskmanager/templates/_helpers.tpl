{{- define "taskmanager.fullname" -}}
{{ .Release.Name }}-taskmanager
{{- end -}}

{{- define "taskmanager.labels" -}}
app.kubernetes.io/name: taskmanager
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}
