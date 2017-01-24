Feature: Block storage
  # Tested features with this scenario:
  #   - Block storage
  #   - Reuse of an existing block storage
  Scenario: Block storage
    Given I am authenticated with "ADMIN" role

    # Archives
    And I checkout the git archive from url "https://github.com/alien4cloud/tosca-normative-types.git" branch "1.2.0"
    And I upload the git archive "tosca-normative-types"
    And I checkout the git archive from url "https://github.com/alien4cloud/alien4cloud-extended-types.git" branch "1.3.0"
    And I upload the git archive "alien4cloud-extended-types/alien-base-types"
    And I upload the git archive "alien4cloud-extended-types/alien-extended-storage-types"
    And I upload the local archive "topologies/block_storage.yaml"

    # Cloudify 3
    And I upload a plugin from maven artifact "alien4cloud:alien4cloud-cloudify3-provider"
#    And I upload a plugin from "../alien4cloud-cloudify3-provider"

    # Orchestrator and location
    And I create an orchestrator named "Mount doom orchestrator" and plugin name "alien-cloudify-3-orchestrator" and bean name "cloudify-orchestrator"
    And I get configuration for orchestrator "Mount doom orchestrator"
    And I update cloudify 3 manager's url to value defined in environment variable "AWS_CLOUDIFY3_MANAGER_URL" for orchestrator with name "Mount doom orchestrator"
    And I update orchestrator "Mount doom orchestrator"'s configuration property "username" to "admin"
    And I update orchestrator "Mount doom orchestrator"'s configuration property "password" to "admin"
    And I enable the orchestrator "Mount doom orchestrator"
    And I create a location named "Thark location" and infrastructure type "amazon" to the orchestrator "Mount doom orchestrator"
    And I create a resource of type "alien.cloudify.aws.nodes.InstanceType" named "Small" related to the location "Mount doom orchestrator"/"Thark location"
    And I update the property "id" to "t2.small" for the resource named "Small" related to the location "Mount doom orchestrator"/"Thark location"
    And I create a resource of type "alien.cloudify.aws.nodes.Image" named "Ubuntu" related to the location "Mount doom orchestrator"/"Thark location"
    And I update the property "id" to "ami-47a23a30" for the resource named "Ubuntu" related to the location "Mount doom orchestrator"/"Thark location"
    And I autogenerate the on-demand resources for the location "Mount doom orchestrator"/"Thark location"
    And I create a resource of type "alien.nodes.aws.PublicNetwork" named "Internet" related to the location "Mount doom orchestrator"/"Thark location"
    And I create a resource of type "alien.cloudify.aws.nodes.Volume" named "SmallBlock" related to the location "Mount doom orchestrator"/"Thark location"
    And I update the property "size" to "1 gib" for the resource named "SmallBlock" related to the location "Mount doom orchestrator"/"Thark location"

    And I create a new application with name "block-storage-cfy3" and description "Block Storage with CFY 3" based on the template with name "block_storage"
    And I Set a unique location policy to "Mount doom orchestrator"/"Thark location" for all nodes
    And I update the property "device" to "/dev/sdf" for the subtituted node "CBS1"
    And I update the property "device" to "/dev/sdg" for the subtituted node "CBS2"
    And I update the property "device" to "/dev/sdh" for the subtituted node "CBS3"
    And I update the property "device" to "/dev/sdi" for the subtituted node "CBS4"

    When I deploy it
    Then I should receive a RestResponse with no error
    And The application's deployment must succeed after 15 minutes
    Then I should have a volume on AWS with id defined in property "volume_id" of the node "CBS1" for "block-storage-cfy3"
    Then I should have a volume on AWS with id defined in property "volume_id" of the node "CBS2" for "block-storage-cfy3"
    Then I should have a volume on AWS with id defined in property "volume_id" of the node "CBS3" for "block-storage-cfy3"
    Then I should have a volume on AWS with id defined in property "volume_id" of the node "CBS4" for "block-storage-cfy3"

    When I upload the local file "data/block_storage_test_file.txt" to the node "Compute"'s remote path "/var/cbs1/block_storage_test_file.txt" with the keypair defined in environment variable "AWS_KEY_PATH" and user "ubuntu"
    When I upload the local file "data/block_storage_test_file.txt" to the node "Compute"'s remote path "/var/cbs2/block_storage_test_file.txt" with the keypair defined in environment variable "AWS_KEY_PATH" and user "ubuntu"
    When I upload the local file "data/block_storage_test_file.txt" to the node "Compute"'s remote path "/var/cbs3/block_storage_test_file.txt" with the keypair defined in environment variable "AWS_KEY_PATH" and user "ubuntu"
    When I upload the local file "data/block_storage_test_file.txt" to the node "Compute"'s remote path "/var/cbs4/block_storage_test_file.txt" with the keypair defined in environment variable "AWS_KEY_PATH" and user "ubuntu"

    And I re-deploy the application
    Then The application's deployment must succeed after 15 minutes

    When I download the remote file "/var/cbs1/block_storage_test_file.txt" from the node "Compute" with the keypair defined in environment variable "AWS_KEY_PATH" and user "ubuntu"
    Then The downloaded file should have the same content as the local file "data/block_storage_test_file.txt"
    When I download the remote file "/var/cbs2/block_storage_test_file.txt" from the node "Compute" with the keypair defined in environment variable "AWS_KEY_PATH" and user "ubuntu"
    Then The downloaded file should have the same content as the local file "data/block_storage_test_file.txt"
    When I download the remote file "/var/cbs3/block_storage_test_file.txt" from the node "Compute" with the keypair defined in environment variable "AWS_KEY_PATH" and user "ubuntu"
    Then The downloaded file should have the same content as the local file "data/block_storage_test_file.txt"
    When I download the remote file "/var/cbs4/block_storage_test_file.txt" from the node "Compute" with the keypair defined in environment variable "AWS_KEY_PATH" and user "ubuntu"
    Then The downloaded file should have the same content as the local file "data/block_storage_test_file.txt"

    When I undeploy it
    Then I should have a volume on AWS with id defined in property "volume_id" of the node "CBS1" for "block-storage-cfy3"
    Then I should have a volume on AWS with id defined in property "volume_id" of the node "CBS2" for "block-storage-cfy3"
    Then I should have a volume on AWS with id defined in property "volume_id" of the node "CBS3" for "block-storage-cfy3"
    Then I should have a volume on AWS with id defined in property "volume_id" of the node "CBS4" for "block-storage-cfy3"
    Then I delete the volume on AWS with id defined in property "volume_id" of the node "CBS1" for "block-storage-cfy3"
    Then I delete the volume on AWS with id defined in property "volume_id" of the node "CBS2" for "block-storage-cfy3"
    Then I delete the volume on AWS with id defined in property "volume_id" of the node "CBS3" for "block-storage-cfy3"
    Then I delete the volume on AWS with id defined in property "volume_id" of the node "CBS4" for "block-storage-cfy3"