package alien4cloud.it;

import cucumber.api.CucumberOptions;
import cucumber.api.junit.Cucumber;
import org.junit.runner.RunWith;

/**
 *
 */
@RunWith(Cucumber.class)
@CucumberOptions(features = { "classpath:features/puccini/docker" }, format = { "pretty", "html:target/cucumber/puccini/docker",
        "json:target/cucumber/puccini/cucumber-docker.json" })
public class RunPucciniDockerIT {
}
