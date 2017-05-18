package alien4cloud.it;

import org.junit.runner.RunWith;

import cucumber.api.CucumberOptions;
import cucumber.api.junit.Cucumber;

/**
 *
 */
@RunWith(Cucumber.class)
@CucumberOptions(features = { "classpath:features/puccini/openstack" }, format = { "pretty", "html:target/cucumber/puccini/openstack",
        "json:target/cucumber/puccini/cucumber-openstack.json" })
public class RunPucciniOpenStackIT {
}
