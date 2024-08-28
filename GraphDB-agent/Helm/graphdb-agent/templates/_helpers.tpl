
{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "eric-data-graph-database-nj.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Chart version.
*/}}
{{- define "eric-data-graph-database-nj.version" -}}
{{- printf "%s" .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Expand the name of the chart.
*/}}
{{- define "eric-data-graph-database-nj.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Ericsson product info annotations. The Chart version should match the product information.
*/}}
{{- define "eric-data-graph-database-nj.prodInfoAnnotations" }}
ericsson.com/product-name: "eric-data-graph-database-nj"
ericsson.com/product-number: "CAV101090/1"
ericsson.com/product-revision: "{{.Values.productInfo.rstate}}"
{{- end -}}

{{/*
Create a default fully qualified app name for core servers.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "eric-data-graph-database-nj.core.name" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s" $name | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create node pod list
*/}}
{{- define "eric-data-graph-database-nj.podsname" -}}
    {{- $fullname := include "eric-data-graph-database-nj.core.name" . -}}
    {{- $port := default 5000 .Values.config.port.discovery -}}
    {{- $service := include "eric-data-graph-database-nj.name" . -}} 
    {{- $release := .Release.Namespace -}}
    {{- $clusterdomain := default "cluster.local" .Values.config.clusterDomain -}}
    {{- $count := (int (index .Values "core" "numberOfServers")) -}}
    {{- range $v := until $count }}{{ $fullname }}-{{ $v }}.{{ $service}}.{{ $release }}.svc.{{ $clusterdomain }}:{{ $port }}{{ if ne $v (sub $count 1) }},{{- end -}}{{- end -}}    
{{- end -}}

{{/*
Create a parameter list 
*/}}
{{- define "eric-data-graph-database-nj.parameters" -}}
{{- $local := dict "first" true -}}
{{- range $k, $v := . -}}{{- if not $local.first -}}{{- "~" -}}{{- end -}}{{- $k -}}{{- "=" -}}{{- $v | quote -}}{{- $_ := set $local "first" false -}}{{- end -}}
{{- end -}}

{{/*
Create a default fully qualified app name for read replica servers.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "eric-data-graph-database-nj.replica.name" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-replica" $name | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name for secrets.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "eric-data-graph-database-nj.secrets.name" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-secrets" $name | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name for physical volumes
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "eric-data-graph-database-nj.pv.name" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-pv" $name | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name for physical volumes claims
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "eric-data-graph-database-nj.pvc.name" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-pvc" $name | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name for logs physical volumes claims
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "eric-data-graph-database-nj.pvc.logs.name" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-logs-pvc" $name | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name for backup physical volumes claims
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "eric-data-graph-database-nj.pvc.backup.name" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-bck-pvc" $name | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}
