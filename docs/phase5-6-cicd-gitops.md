# Phase 5-6 - CI/CD and GitOps

## CI (Jenkins 10.30.5.41)
- Stages: Build&Test (Maven in container) -> SonarQube -> Quality Gate
  -> Docker build/push (tag = git short SHA) -> commit tag to overlays/dev
- Credentials in Jenkins only: sonarqube-token, dockerhub, github-token
- SonarQube 26.x blocks webhooks to private IPs by default
  -> disabled "local webhooks validation" (internal network only)

## CD (Argo CD v3.5.5 in nonprod, chart 10.10.5)
- dev/staging: auto-sync (prune + selfHeal) on nonprod
- prod: separate cluster, MANUAL sync = release approval
- Promotion = git commit copying the tag; rollback = git revert
- Monitoring: kube-prometheus-stack 91.9.0 via Argo CD, Grafana :30300
