# Infrastructure Resource Guide (Internal Project Metadata)

This document details the specific configuration requirements and implementation rationale for the `simple-terraform-learning` project. General cloud concepts are omitted in favor of project-specific technical decisions.

## 1. Compute Layer: Elastic Beanstalk Specifics

### Network & Security Architecture
- **VPC Dynamic Discovery**: Utilizes data-source filters (`state = available`) to dynamically resolve existing networking infrastructure rather than creating new subnets.
- **Internal ELB Scheme**: Specifically configured with `ELBScheme = "internal"` to ensure the application remains strictly internal-facing and is not exposed to the public internet.
- **IAM Hardening**: Points to pre-existing Service (`aws-elasticbeanstalk-service-role`) and Instance Profile (`aws-elasticbeanstalk-ec2-role`) roles to comply with strict security boundary requirements.

### Lifecycle & Deployment Policy
- **S3 Storage Optimization**: `appversion_lifecycle` is set to `max_count = 100` with `delete_source_from_s3 = true` to automatically purge legacy build artifacts and manage S3 costs.
- **Rapid Update Trigger**: Deployment policy is set to `AllAtOnce` with `RollingUpdateEnabled = false`. This is intentionally configured for the `dev` environment to allow rapid "un-wedging" of the environment during frequent CI/CD iterations.
- **Spring Boot Environment**: Hardcoded environment variables include `SPRING_PROFILES_ACTIVE=dev` and `JAVA_OPTS=-Xmx512m`, tailoring the JVM to `t3a.medium` memory constraints.

### Core Runtime
- **Application Versioning**: Implements a unique version label logic using `formatdate("YYYYMMDDhhmmss", timestamp())` to prevent deployment collisions in high-frequency pipelines.
- **Managed Health Check**: Specifically targets `/actuator/health` on port `8080`, aligning with the Spring Boot Actuator standard for deep health checks (DB, Disk, Memory).

---

## 2. Advanced Observability & Monitoring

### Persistence & Retention
- **Log Group Adoption**: Log groups (`web.stdout.log`, `eb-engine.log`, etc.) are pre-created with a **30-day retention policy**. This prevents the data loss that occurs during standard Beanstalk environment termination.
- **Enhanced Health Configuration**: A custom `ConfigDocument` JSON is implemented to force-stream `RootFilesystemUtil` and `ApplicationLatencyP95` metrics into CloudWatch, bypassing standard health reporting limitations.

### Alarm & Dimension Logic
- **Dimension Specificity**: Alarms are strictly locked to the `EnvironmentName` dimension.
    - **Why Required**: CloudWatch metrics are uniquely identified by their dimensions. Without `EnvironmentName`, the alarm cannot distinguish between metrics from different environments (e.g., Dev vs. Prod).
    - **Stability Requirement**: Using the aggregate environment dimension instead of `InstanceId` prevents "orphaned" alarms. It ensures the monitoring layer remains functional even when EC2 instances or Auto Scaling Groups are replaced during rolling updates.
- **Log-Based Error Detection**: 
    - **Pattern**: `?ERROR ?Exception ?"error" ?"FATAL" ?"ORA-"`
    - **Rationale**: The inclusion of `ORA-` specifically monitors for Oracle JDBC/Connection Pool failures, which are critical for this application's database reliance.

### Alerting Pipeline
- **CloudWatch SNS Policy**: A dedicated IAM policy statement allows the `cloudwatch.amazonaws.com` service to interact with the SNS alert topic, ensuring that health state transitions (OK -> ALARM) correctly trigger notifications.
