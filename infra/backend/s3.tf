# s3.tf
#
# O bucket é criado via null_resource em main.tf para contornar a SCP do
# AWS Academy Learner Lab que bloqueia s3:GetBucketObjectLockConfiguration.
# Este arquivo não declara aws_s3_bucket para evitar esse erro.
#
# Todas as configurações (versioning, SSE-AES256, public access block) são
# aplicadas por AWS CLI dentro do null_resource.s3_bucket.
