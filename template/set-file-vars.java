import static java.nio.charset.StandardCharsets.UTF_8;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardOpenOption;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * Usage: java set-file-vars.java -Dreplace.AAA=BBB -Dreplace.CCC=DDD textfile.txt
 * Will replace "AAA" to "BBB" and "CCC" to "DDD" in textfile.txt (UTF-8)
 */
public class Main {

	private static final String REPLACE_TOKEN = "replace.";

	public static void main(final String[] args) throws Exception {
		final var path = Path.of(args[0]);
		if (Files.isWritable(path) == false) {
			throw new IOException("Can't write in file " + path);
		}

		final var toReplaces = System.getProperties().entrySet().stream()
		        .filter(p -> p.getKey() instanceof String && p.getValue() instanceof String)
		        .filter(p -> ((String) p.getKey()).startsWith(REPLACE_TOKEN))
		        .collect(Collectors.toUnmodifiableMap(p -> {
			        return ((String) p.getKey()).substring(REPLACE_TOKEN.length());
		        }, p -> {
			        return (String) p.getValue();
		        }));

		final var newContent = Files.lines(path, UTF_8).map(line -> {
			String result = line;
			for (final Map.Entry<String, String> entry : toReplaces.entrySet()) {
				result = result.replace(entry.getKey(), entry.getValue());
			}
			return result;
		}).collect(Collectors.joining(System.lineSeparator(), "", System.lineSeparator()));
		Files.writeString(path, newContent, StandardOpenOption.WRITE, StandardOpenOption.TRUNCATE_EXISTING);
	}

}