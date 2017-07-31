package alien4cloud.it.provider;

import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.util.Iterator;
import java.util.Map;
import java.util.Map.Entry;

import org.apache.commons.collections4.MapUtils;
import org.apache.commons.lang3.StringUtils;
import org.junit.Assert;

import alien4cloud.it.Context;
import alien4cloud.it.application.ApplicationStepDefinitions;
import alien4cloud.it.application.deployment.ApplicationsDeploymentStepDefinitions;
import alien4cloud.it.common.CommonStepDefinitions;
import alien4cloud.it.orchestrators.OrchestratorsDefinitionsSteps;
import alien4cloud.it.provider.ByonStepDefinitions.ComputeInstance;
import alien4cloud.it.provider.ByonStepDefinitions.OpenstackComputeInstance;
import alien4cloud.it.provider.util.OpenStackClient;
import alien4cloud.it.setup.SetupStepDefinitions;
import alien4cloud.model.application.Application;
import alien4cloud.rest.utils.RestClient;
import cucumber.api.java.After;
import cucumber.api.java.Before;
import cucumber.api.java.en.And;
import lombok.extern.slf4j.Slf4j;

@Slf4j
public class Setup {

    public static final String OPENSTACK_URL_ENV_NAME = "OPENSTACK_CLOUDIFY3_MANAGER_URL";

    private static final SetupStepDefinitions SETUP_STEP_DEFINITIONS = new SetupStepDefinitions();

    private static final CommonStepDefinitions COMMON_STEP_DEFINITIONS = new CommonStepDefinitions();

    private static final ApplicationsDeploymentStepDefinitions APPLICATIONS_DEPLOYMENT_STEP_DEFINITIONS = new ApplicationsDeploymentStepDefinitions();

    private static final OrchestratorsDefinitionsSteps ORCHESTRATORS_DEFINITIONS_STEPS = new OrchestratorsDefinitionsSteps();

    private static final ByonStepDefinitions BYON_STEP_DEFINITIONS = new ByonStepDefinitions();

    static {
        Runtime.getRuntime().addShutdownHook(new Thread() {
            @Override
            public void run() {
                log.info("Wait for resources to be released on cloudify side before terminating the VM");
                // TODO For asynchronous problem of cloudify
                try {
                    Thread.sleep(60 * 1000L);
                } catch (InterruptedException e) {
                }
                log.info("Finished waiting, the VM will be terminated right after");
            }
        });
    }

    @Before
    public void beforeScenario() throws Throwable {
        log.info("Clean up before scenario");
        COMMON_STEP_DEFINITIONS.beforeScenario();
    }

    @After
    public void afterScenario() throws Throwable {
        log.info("Clean up deployed applications");
        if (MapUtils.isNotEmpty(ApplicationStepDefinitions.CURRENT_APPLICATIONS)) {
            for (Application application : ApplicationStepDefinitions.CURRENT_APPLICATIONS.values()) {
                APPLICATIONS_DEPLOYMENT_STEP_DEFINITIONS.I_undeploy_it(application, true);
            }
            ApplicationStepDefinitions.CURRENT_APPLICATIONS.clear();
        }
        if (ApplicationStepDefinitions.CURRENT_APPLICATION != null) {
            APPLICATIONS_DEPLOYMENT_STEP_DEFINITIONS.I_undeploy_it(ApplicationStepDefinitions.CURRENT_APPLICATION, true);
            ApplicationStepDefinitions.CURRENT_APPLICATION = null;
        }
        cleanupCreatedResources();
        ORCHESTRATORS_DEFINITIONS_STEPS.I_disable_all_orchestrators();
    }

    private void cleanupCreatedResources() {
        Map<String, ComputeInstance> createdCompute = ByonStepDefinitions.CREATED_COMPUTES;
        if (!createdCompute.isEmpty()) {
            OpenStackClient osClient = Context.getInstance().getOpenStackClient();
            createdCompute.entrySet().stream().filter(entry -> entry.getValue() instanceof OpenstackComputeInstance).forEach(entry -> {
                ComputeInstance instance = entry.getValue();
                osClient.deleteCompute(instance.getId());
                if (StringUtils.isNotBlank(instance.getFloatingIpId())) {
                    osClient.deleteFloatingIp(instance.getFloatingIpId());
                }
            });
        }
    }

    @And("^I upload a plugin from maven artifact \"([^\"]*)\"$")
    public void I_upload_a_plugin_from_maven_artifact(String artifact) throws Throwable {
        String[] artifactTokens = artifact.split(":");
        Assert.assertTrue(artifactTokens.length == 2 || artifactTokens.length == 3);
        String version = Context.VERSION;
        if (artifactTokens.length == 3) {
            version = artifactTokens[2];
        }
        String repository;
        if (version.endsWith("SNAPSHOT")) {
            repository = "opensource-snapshot";
        } else {
            repository = "opensource";
        }
        String groupId = artifactTokens[0];
        String artifactId = artifactTokens[1];
        String artifactUrl = Context.FASTCONNECT_NEXUS + "r=" + repository + "&g=" + groupId + "&a=" + artifactId + "&v=" + version + "&p=zip";
        Path tempFile = Files.createTempFile(null, null);
        Files.copy(new RestClient(artifactUrl).getAsStream(""), tempFile, StandardCopyOption.REPLACE_EXISTING);
        Context.getInstance().registerRestResponse(Context.getRestClientInstance().postMultipart("/rest/plugins", "file", Files.newInputStream(tempFile)));
        COMMON_STEP_DEFINITIONS.I_should_receive_a_RestResponse_with_no_error();
    }
}
