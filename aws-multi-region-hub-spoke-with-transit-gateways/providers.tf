# Configure AWS providers for different regions
provider "aws" {
  alias  = "eu_central"
  region = "eu-central-1"
}

provider "aws" {
  alias  = "us_east"
  region = "us-east-1"
}

provider "aws" {
  alias  = "eu_west"
  region = "eu-west-1"
} 