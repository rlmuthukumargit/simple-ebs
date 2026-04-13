# Grafana Dashboard Setup Guide — Spring Boot on Elastic Beanstalk

Complete step-by-step instructions to configure a Grafana dashboard with **application logs** and **all CloudWatch metric panels** for your Elastic Beanstalk deployment.

> **Prerequisite**: Grafana must be connected to AWS CloudWatch using a Role ARN with read access to CloudWatch Metrics and Logs.

---

## Table of Contents

- [Part A: Application Logs Panel](#part-a-application-logs-panel)
- [Part B: CloudWatch Metric Panels](#part-b-cloudwatch-metric-panels)
  - [Panel 1: Environment Health](#panel-1-environment-health)
  - [Panel 2: CPU Utilization](#panel-2-cpu-utilization)
  - [Panel 3: Application 5xx Errors](#panel-3-application-5xx-errors)
  - [Panel 4: Response Latency](#panel-4-response-latency)
  - [Panel 5: Application Log Errors](#panel-5-application-log-errors-custom-metric)
  - [Panel 6: EB Engine Errors](#panel-6-eb-engine-errors-custom-metric)
  - [Panel 7: Nginx Errors](#panel-7-nginx-errors-custom-metric)
- [Part C: Recommended Dashboard Layout](#part-c-recommended-dashboard-layout)
- [Part D: Troubleshooting](#part-d-troubleshooting)

---

## Part A: Application Logs Panel

This panel shows your **live Spring Boot application logs** (`web.stdout.log`).

### Step 1: Create a New Dashboard

1. In Grafana, click **Dashboards** → **New** → **New Dashboard**
2. Click **Add visualization**

### Step 2: Configure the Logs Panel

| Setting | Value |
|---|---|
| **Data Source** | `CloudWatch` (your existing one) |
| **Query Mode** | `CloudWatch Logs` |
| **Region** | `us-east-2` |
| **Log Groups** | `/aws/elasticbeanstalk/<env-name>/environment/web.stdout.log` |

### Step 3: Enter the Query

```
fields @timestamp, @message
| sort @timestamp desc
| limit 500
```

### Step 4: Set Visualization

1. In the right panel, change visualization type to **Logs**
2. Set panel title: `📋 Spring Boot Application Logs`
3. Click **Apply**

### Step 5 (Optional): Add Error-Only Logs Panel

Repeat steps above with a second panel using this query:

```
fields @timestamp, @message
| filter @message like /ERROR|Exception|FATAL|ORA-/
| sort @timestamp desc
| limit 200
```

- Title: `🔴 Application Errors`

---

## Part B: CloudWatch Metric Panels

For each panel below:

1. Click **Add** → **Visualization**
2. Select your **CloudWatch** data source
3. Set **Query Mode** to `CloudWatch Metrics`
4. Set **Region** to `us-east-2`
5. Configure the fields as shown
6. Set the visualization type as recommended
7. Click **Apply**

> **Note:** Replace `<env-name>` with your actual EB environment name (e.g. `Tss-salestax-d1-us-east-2-env`).

---

### Panel 1: Environment Health

| Field | Value |
|---|---|
| **Namespace** | `AWS/ElasticBeanstalk` |
| **Metric Name** | `EnvironmentHealth` |
| **Statistic** | `Maximum` |
| **Period** | `1 minute` |
| **Dimensions** | `EnvironmentName` = `<env-name>` |

| Panel Setting | Value |
|---|---|
| **Visualization** | `Stat` |
| **Title** | `🏥 Environment Health` |
| **Value Mappings** | `0` → `OK 🟢`, `1` → `Info 🔵`, `5` → `Warning 🟡`, `15` → `Degraded 🟠`, `20` → `Severe 🔴`, `25` → `Danger ⛔` |
| **Thresholds** | Green: 0, Yellow: 1, Orange: 15, Red: 20 |

> **Tip:** EB EnvironmentHealth values: 0=OK, 1=Info, 5=Warning, 15=Degraded, 20=Severe, 25=Danger

---

### Panel 2: CPU Utilization

| Field | Value |
|---|---|
| **Namespace** | `AWS/ElasticBeanstalk` |
| **Metric Name** | `CPUUtilization` |
| **Statistic** | `Average` |
| **Period** | `5 minutes` |
| **Dimensions** | `EnvironmentName` = `<env-name>` |

| Panel Setting | Value |
|---|---|
| **Visualization** | `Gauge` or `Time Series` |
| **Title** | `🖥️ CPU Utilization (%)` |
| **Unit** | `Percent (0-100)` |
| **Min** | `0` |
| **Max** | `100` |
| **Thresholds** | Green: 0-60, Yellow: 60-80, Red: 80+ |

---

### Panel 3: Application 5xx Errors

| Field | Value |
|---|---|
| **Namespace** | `AWS/ElasticBeanstalk` |
| **Metric Name** | `ApplicationRequests5xx` |
| **Statistic** | `Sum` |
| **Period** | `1 minute` |
| **Dimensions** | `EnvironmentName` = `<env-name>` |

| Panel Setting | Value |
|---|---|
| **Visualization** | `Time Series` (bar style) |
| **Title** | `⚠️ 5xx Errors` |
| **Unit** | `short` |
| **Thresholds** | Green: 0, Yellow: 5, Red: 10 |
| **Draw Style** | `Bars` |

---

### Panel 4: Response Latency (Duration)

| Field | Value |
|---|---|
| **Namespace** | `AWS/ElasticBeanstalk` |
| **Metric Name** | `Duration` |
| **Statistic** | `Average` |
| **Period** | `1 minute` |
| **Dimensions** | `EnvironmentName` = `<env-name>` |

| Panel Setting | Value |
|---|---|
| **Visualization** | `Time Series` |
| **Title** | `⏱️ Avg Response Latency` |
| **Unit** | `seconds (s)` |
| **Thresholds** | Green: 0-0.5, Yellow: 0.5-1, Red: 1+ |

---

### Panel 5: Application Log Errors (Custom Metric)

| Field | Value |
|---|---|
| **Namespace** | `Custom/<app-name>` |
| **Metric Name** | `<app-name>-AppErrorCount` |
| **Statistic** | `Sum` |
| **Period** | `5 minutes` |
| **Dimensions** | _(none — custom metrics have no dimensions)_ |

| Panel Setting | Value |
|---|---|
| **Visualization** | `Time Series` (bar style) |
| **Title** | `🔴 App Log Errors (ERROR/Exception/ORA-)` |
| **Unit** | `short` |
| **Thresholds** | Green: 0, Yellow: 3, Red: 5 |
| **Draw Style** | `Bars` |

> This metric is generated by a CloudWatch Log Metric Filter scanning `web.stdout.log` for patterns: `ERROR`, `Exception`, `FATAL`, `ORA-`.

---

### Panel 6: EB Engine Errors (Custom Metric)

| Field | Value |
|---|---|
| **Namespace** | `Custom/<app-name>` |
| **Metric Name** | `<app-name>-EBEngineErrorCount` |
| **Statistic** | `Sum` |
| **Period** | `5 minutes` |
| **Dimensions** | _(none)_ |

| Panel Setting | Value |
|---|---|
| **Visualization** | `Time Series` (bar style) |
| **Title** | `🔧 EB Engine Errors` |
| **Unit** | `short` |
| **Thresholds** | Green: 0, Yellow: 2, Red: 3 |
| **Draw Style** | `Bars` |

> This metric is generated by a CloudWatch Log Metric Filter scanning `eb-engine.log` for patterns: `ERROR`, `Failed`, `failed`.

---

### Panel 7: Nginx Errors (Custom Metric)

| Field | Value |
|---|---|
| **Namespace** | `Custom/<app-name>` |
| **Metric Name** | `<app-name>-NginxErrorCount` |
| **Statistic** | `Sum` |
| **Period** | `5 minutes` |
| **Dimensions** | _(none)_ |

| Panel Setting | Value |
|---|---|
| **Visualization** | `Time Series` (bar style) |
| **Title** | `🌐 Nginx Errors` |
| **Unit** | `short` |
| **Thresholds** | Green: 0, Yellow: 5, Red: 10 |
| **Draw Style** | `Bars` |

> This metric is generated by a CloudWatch Log Metric Filter scanning `nginx/error.log` for patterns: `error`, `crit`, `alert`, `emerg`.

---

## Part C: Recommended Dashboard Layout

```
┌──────────────────────────────────────────────────────────┐
│  Row 1: Overview                                         │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐ │
│  │ Env      │  │ CPU      │  │ 5xx      │  │ Latency  │ │
│  │ Health   │  │ Util %   │  │ Errors   │  │ (Avg)    │ │
│  │ (Stat)   │  │ (Gauge)  │  │ (Bars)   │  │ (Line)   │ │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘ │
├──────────────────────────────────────────────────────────┤
│  Row 2: Log-Based Error Metrics                          │
│  ┌────────────────┐  ┌────────────────┐  ┌────────────┐ │
│  │ App Log Errors  │  │ EB Engine Err  │  │ Nginx Err  │ │
│  │ (Bars)          │  │ (Bars)         │  │ (Bars)     │ │
│  └────────────────┘  └────────────────┘  └────────────┘ │
├──────────────────────────────────────────────────────────┤
│  Row 3: Live Logs (full width)                           │
│  ┌──────────────────────────────────────────────────────┐│
│  │ 📋 Spring Boot Application Logs                      ││
│  │ (Logs panel — full width)                            ││
│  └──────────────────────────────────────────────────────┘│
├──────────────────────────────────────────────────────────┤
│  Row 4: Error Logs (full width)                          │
│  ┌──────────────────────────────────────────────────────┐│
│  │ 🔴 Application Errors Only                           ││
│  │ (Logs panel — filtered for ERROR/Exception)          ││
│  └──────────────────────────────────────────────────────┘│
└──────────────────────────────────────────────────────────┘
```

### Final Steps

1. Click **Save dashboard** (💾 icon)
2. Name it: `EB - Spring Boot Monitoring`
3. Set **auto-refresh** to `30s` or `1m` from the top-right dropdown
4. Set **time range** to `Last 1 hour` for real-time monitoring

---

## Part D: Troubleshooting

### Metrics not appearing in Grafana dropdown

- **Set the Dimension first**, then select the Metric Name
- If dropdowns show "No options found", **type the values manually** and press Enter
- Ensure your Grafana IAM Role has `cloudwatch:ListMetrics` and `cloudwatch:GetMetricData`

### Metrics missing from CloudWatch entirely

| Metric Type | Cause | Fix |
|---|---|---|
| `EnvironmentHealth` only | ConfigDocument not applied | Run `terraform apply` to apply the enhanced health ConfigDocument |
| No request metrics (5xx, Duration) | No HTTP traffic to the app | Send requests to the app URL, wait 5 minutes |
| Custom metrics (5, 6, 7) | No matching log events yet | Generate app activity that produces log output |

### CloudWatch custom metrics showing "—" in EB Console

The `ConfigDocument` must include both **Environment** and **Instance** level metrics. Verify in:
- **AWS Console → EB → Configuration → Monitoring**
- Both "CloudWatch custom metrics - environment" and "instance" should show values

If they show "—", run the pipeline to apply the Terraform ConfigDocument.

### Request metrics (5xx, 4xx, Duration) not appearing

These metrics **only publish when the application receives HTTP requests**. Hit your application URL:

```bash
curl http://<your-eb-url>/actuator/health
```

Wait 5 minutes, then check CloudWatch.

---

## Quick Reference — All Namespaces & Metrics

### Environment-Level Metrics (via ConfigDocument)

| # | Panel | Namespace | Metric | Stat | Period | Dimension |
|---|---|---|---|---|---|---|
| 1 | Env Health | `AWS/ElasticBeanstalk` | `EnvironmentHealth` | Max | 1m | `EnvironmentName` |
| 2 | CPU | `AWS/ElasticBeanstalk` | `CPUUtilization` | Avg | 5m | `EnvironmentName` |
| 3 | 5xx | `AWS/ElasticBeanstalk` | `ApplicationRequests5xx` | Sum | 1m | `EnvironmentName` |
| 4 | Latency | `AWS/ElasticBeanstalk` | `Duration` | Avg | 1m | `EnvironmentName` |
| 5 | App Errors | `Custom/<app-name>` | `<app-name>-AppErrorCount` | Sum | 5m | none |
| 6 | EB Engine | `Custom/<app-name>` | `<app-name>-EBEngineErrorCount` | Sum | 5m | none |
| 7 | Nginx | `Custom/<app-name>` | `<app-name>-NginxErrorCount` | Sum | 5m | none |

### Instance-Level Metrics (via ConfigDocument)

These are also published to CloudWatch for per-instance monitoring:

| Metric | Description |
|---|---|
| `CPUUtilization` | CPU usage per instance |
| `InstanceHealth` | Health status per instance |
| `ApplicationRequests5xx` | 5xx errors per instance |
| `ApplicationRequests4xx` | 4xx errors per instance |
| `ApplicationRequests2xx` | 2xx (success) per instance |
| `ApplicationRequests3xx` | 3xx (redirect) per instance |
| `ApplicationRequestsTotal` | Total requests per instance |
| `RootFilesystemUtil` | Disk usage per instance |
| `LoadAverage1min` | 1-minute load average per instance |

### Log Groups (for Logs panels)

| Log Group Path | Content |
|---|---|
| `/aws/elasticbeanstalk/<env-name>/environment/web.stdout.log` | Spring Boot application output |
| `/aws/elasticbeanstalk/<env-name>/environment/eb-engine.log` | EB platform/deployment logs |
| `/aws/elasticbeanstalk/<env-name>/environment/nginx/error.log` | Nginx proxy errors |
| `/aws/elasticbeanstalk/<env-name>/environment/nginx/access.log` | Nginx access logs |
