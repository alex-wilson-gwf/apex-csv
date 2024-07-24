public class RT_CSVReader implements Iterable<List<String>>, Iterator<List<String>> {

	private final static String COMMA = ',';
	private final static String CR = '\r';
	private final static String LF = '\n';
	private final static String CRLF = '\r\n';
	private final static String QUOTE = '"';
	private final static String DOUBLE_QUOTE = '""';
	private final static String DOUBLE_QUOTE_REPLACEMENT = '¿¡DB~QT!?';
	private final static String SPACE = ' ';

	
	private String csvString;
	private Integer csvStringLength;
	private Integer position = 0;
	private Iterator<List<String>> it;
	
	public RT_CSVReader(String csvString) {
		csvString = csvString.replace(DOUBLE_QUOTE, DOUBLE_QUOTE_REPLACEMENT); //APW: Swap double double quotes for an arbirary string to prevent issues
		this.csvString = convertLineEndings(csvString.trim());
		this.csvStringLength = csvString.length();
		this.it = iterator();
	}
	
	public static List<List<String>> read(String csvString) {
		List<List<String>> res = new List<List<String>>();
		RT_CSVReader reader = new RT_CSVReader(csvString);
		while (reader.it.hasNext()) {
			res.add(reader.it.next());
		}
		return res;
	}
	
	private static String convertLineEndings(String str) {
		return str.replace(CRLF, LF).replace(CR, LF);
	}
	
	public Iterator<List<String>> iterator() {
		return this;
	}
	
	public Boolean hasNext() {
		return position < csvStringLength;
	}
	
	public List<String> next() {
		List<String> values = new List<String>();
		position = readLine(position, values);
		return values;
	}
	
	private Integer readLine(Integer position, List<String> values) {
		Integer startPos = position;
		
		String currentValue;
		Integer cAt, nlAt, foundAt;
		
		List<String> tmpValues = new List<String>();
		while (position < csvStringLength) {
			cAt = csvString.indexOf(COMMA, position);
			nlAt = csvString.indexOf(LF, position);
			foundAt = Math.min(cAt, nlAt);
			
			if (foundAt < 0) {
				foundAt = Math.max(cAt, nlAt);
			}
			if (foundAt < 0) {
				currentValue = csvString.substring(startPos);
				position = csvStringLength;
			}
			else {
				currentValue = csvString.substring(startPos, foundAt);
				position = foundAt + 1;
			}
			
			if (!currentValue.startsWith(QUOTE)) {
				tmpValues.add(currentValue);
				
				if (foundAt == nlAt) {
					break;
				}
				startPos = position;
			}
			else if (currentValue == DOUBLE_QUOTE) {
				tmpValues.add('');
				if (foundAt == nlAt) {
					break;
				}
				startPos = position;
			}
			else if (currentValue.endsWith(QUOTE)) {
				Integer lastIndex = currentValue.length() - 1;
				currentValue = currentValue.substring(1, lastIndex);
				
				//Does it contain double quoted quotes? I.e. Escaped double quotes
                		Integer doubleQuotedQuotesIndex = currentValue.indexOf(DOUBLE_QUOTE);
                		if(doubleQuotedQuotesIndex >= 0) {
                    			// Replace double quoted quotes with double quotes.
                    			currentValue = currentValue.replace(DOUBLE_QUOTE, QUOTE);
                		}


						
				tmpValues.add(currentValue);
				if (foundAt == nlAt) {
					break;
				}
				startPos = position;
			}
		}

		for (Integer i = 0; i < tmpValues.size(); i++) {
			//APW: Undo the work we did at the top to stop issues with double quotes
			if (tmpValues[i].indexOf(DOUBLE_QUOTE_REPLACEMENT) >= 0) {
				tmpValues[i] = tmpValues[i].replace(DOUBLE_QUOTE_REPLACEMENT, DOUBLE_QUOTE);
			}
			//APW: Add quotes to fields that need it. source: https://en.wikipedia.org/wiki/Comma-separated_values#Basic_rules
			if (tmpValues[i].indexOf(COMMA) >= 0 || tmpValues[i].indexOf(CR) >= 0 || tmpValues[i].indexOf(LF) >= 0 || (tmpValues[i].indexOf(DOUBLE_QUOTE) >= 0 && tmpValues[i] != DOUBLE_QUOTE) || tmpValues[i].startsWith(SPACE) || tmpValues[i].endsWith(SPACE)) {
					tmpValues[i] = '"' + tmpValues[i] + '"';
			}
		}

		values.addAll(tmpValues);
		return position;
	}
}
