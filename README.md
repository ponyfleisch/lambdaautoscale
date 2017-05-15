This is a terraform module. Use it inside your terraform project like this:

### autoscaling.tf
```
provider "aws" {
  region = "ap-southeast-1"
  # add key and secret key if needed (or provide in ~/.aws/credentials)
}

module "autoscaling" {
  source = "github.com/ponyfleisch/lambdaautoscale"
  name = "foobar"
  region = "ap-southeast-1"
  secret = "schnitzelbrot"
}
```
Then execute:
```bash
terraform get
terraform apply
terraform output --module=autoscaling
```

The js files need to be added to the respective zip files manually after editing.
