aws dynamodb query \
    --table-name ab-img-metadata \
    --key-condition-expression "DetectedObjects = :name" \
    --expression-attribute-values  '{":name":{"S":"car"}}'