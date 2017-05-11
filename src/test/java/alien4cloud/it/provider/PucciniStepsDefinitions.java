package alien4cloud.it.provider;

import java.io.IOException;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Map;

import org.apache.commons.lang.StringUtils;
import org.junit.Assert;

import com.google.common.collect.Lists;
import com.google.common.collect.Maps;

import alien4cloud.it.Context;
import alien4cloud.rest.orchestrator.model.UpdateLocationResourceTemplatePropertyRequest;
import alien4cloud.rest.utils.JsonUtil;
import alien4cloud.utils.FileUtil;
import cucumber.api.java.en.Given;
import cucumber.api.java.en.When;

public class PucciniStepsDefinitions {

    @Given("^I set the information AccessKeyId, AccessKeySecret, RegionID defined in the environment for the account AWS for puccini orchestrator \"(.*?)\"$")
    public void i_set_configuration_for_puccini_orchestrator_with_my_account_AWS(String orchestratorName) throws Throwable {
        Map<String, Object> configuration = Context.getInstance().getOrchestratorConfiguration();
        Map<String, Object> configurationLocationConfigurations = Maps.newHashMap();
        Map<String, Object> configurationAws = Maps.newHashMap();
        Map<String, Object> configurationDefaultConfiguration = Maps.newHashMap();
        configuration.put("locationConfigurations", configurationLocationConfigurations);
        configurationLocationConfigurations.put("aws", configurationAws);
        configurationAws.put("defaultConfiguration", configurationDefaultConfiguration);
        String accessKeyId = System.getenv("accessKeyId");
        Assert.assertTrue(accessKeyId + " is not defined", StringUtils.isNotBlank(accessKeyId));
        String accessKeySecret = System.getenv("accessKeySecret");
        Assert.assertTrue(accessKeySecret + " is not defined", StringUtils.isNotBlank(accessKeySecret));
        String region = System.getenv("region");
        Assert.assertTrue(region + " is not defined", StringUtils.isNotBlank(region));
        configurationDefaultConfiguration.put("accessKeyId", accessKeyId);
        configurationDefaultConfiguration.put("accessKeySecret", accessKeySecret);
        configurationDefaultConfiguration.put("region", region);
        Context.getInstance().setOrchestratorConfiguration(configuration);
        String orchestratorId = Context.getInstance().getOrchestratorId(orchestratorName);
        String restResponse = Context.getRestClientInstance().putJSon("/rest/v1/orchestrators/" + orchestratorId + "/configuration",
                JsonUtil.toString(configuration));
        Context.getInstance().registerRestResponse(restResponse);
    }

    @When("^I update the property \"([^\"]*)\" to a list \"([^\"]*)\" for the resource named \"([^\"]*)\" related to the location \"([^\"]*)\"/\"([^\"]*)\"$")
    public void I_update_the_property_to_for_the_resource_named_related_to_the_location_with_a_list(String propertyName, String propertyValue,
            String resourceName, String orchestratorName, String locationName) throws Throwable {
        String[] elements = propertyValue.split(",");
        List<String> propertyList = new ArrayList<>();
        for (String element : elements) {
            propertyList.add(element);
        }
        updatePropertyValue(orchestratorName, locationName, resourceName, propertyName, propertyList,
                "/rest/v1/orchestrators/%s/locations/%s/resources/%s/template/properties");
    }

    private void updatePropertyValue(String orchestratorName, String locationName, String resourceName, String propertyName, Object propertyValue,
            String restUrlFormat, String... extraArgs) throws IOException {
        String orchestratorId = Context.getInstance().getOrchestratorId(orchestratorName);
        String locationId = Context.getInstance().getLocationId(orchestratorId, locationName);
        String resourceId = Context.getInstance().getLocationResourceId(orchestratorId, locationId, resourceName);
        String restUrl;
        if (extraArgs.length > 0) {
            List<String> args = Lists.newArrayList(orchestratorId, locationId, resourceId);
            args.addAll(Arrays.asList(extraArgs));
            restUrl = String.format(restUrlFormat, args.toArray());
        } else {
            restUrl = String.format(restUrlFormat, orchestratorId, locationId, resourceId);
        }
        UpdateLocationResourceTemplatePropertyRequest request = new UpdateLocationResourceTemplatePropertyRequest();
        request.setPropertyName(propertyName);
        request.setPropertyValue(propertyValue);
        String resp = Context.getRestClientInstance().postJSon(restUrl, JsonUtil.toString(request));
        Context.getInstance().registerRestResponse(resp);
    }

    @When("^I upload an artifact whose path is defined in the environment variable \"([^\"]*)\" for the property \"([^\"]*)\" of the resource named \"([^\"]*)\" related to the location \"([^\"]*)\"/\"([^\"]*)\"$")
    public void I_upload_an_artifact_whose_path_is_defined_in_the_environment_variable_for_the_property_of_the_resource(String environmentVariable,
            String property, String resourceName, String orchestratorName, String locationName) throws IOException {
        String artifactPathString = System.getenv(environmentVariable);
        Assert.assertTrue(artifactPathString + " is not defined", StringUtils.isNotBlank(artifactPathString));
        Path artifactPath = Paths.get(artifactPathString);
        String keyFileString = FileUtil.readTextFile(artifactPath);
        updatePropertyValue(orchestratorName, locationName, resourceName, property, keyFileString,
                "/rest/v1/orchestrators/%s/locations/%s/resources/%s/template/properties");

    }

}
