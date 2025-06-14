aws ec2 describe-instances --filters Name=tag:Name,Values=LogParserInstance --query 'Reservations[*].Instances[*].[InstanceId, State.Name, PublicIpAddress]' --output table
