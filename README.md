# Django AWS Infrastructure

![Architecture diagram](django-aws-infra.webp "Architecture diagram")

## Provisioning

```
terraform apply
```

## Load Testing

On Mac:

```
brew install k6
```
Then run:

```
k6 run load_test.js
```