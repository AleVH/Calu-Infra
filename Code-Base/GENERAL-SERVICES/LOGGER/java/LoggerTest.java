
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class LoggerTest {
    private static final Logger logger = LoggerFactory.getLogger("test-java");

    public static void main(String[] args) {
        logger.info("Logger test (info)");
        logger.warn("Logger test (warn)");
        logger.error("Logger test (error)");
    }
}
