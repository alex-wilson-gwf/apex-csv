//https://github.com/redteal/apex-csv

public class R_CSVReader implements Iterable<List<String>>, Iterator<List<String>> {

	private final static String COMMA = ',';
	private final static String CR = '\r';
	private final static String LF = '\n';
	private final static String CRLF = '\r\n';
	private final static String LFCR = '\n\r';
	private final static String DQUOTE = '"';
	private final static String DQUOTEDQUOTE = '""';
	private final static String DQUOTEDQUOTE_REPLACEMENT = '¿¡DB~QT!?';
	private final static String SP = ' ';

	
	private String csvString;
	private Integer csvStringLength;
	private Integer position = 0;
	private Iterator<List<String>> it;
	
	public RT_CSVReader(String csvString) {
		csvString = csvString.replace(DQUOTEDQUOTE, DQUOTEDQUOTE_REPLACEMENT); //APW: Swap double double quotes for an arbirary string to prevent issues
		this.csvString = convertLineEndings(csvString.trim());
		this.csvStringLength = csvString.length();
		this.it = iterator();
	}
	
	public static List<List<String>> read(String csvString) {
		List<List<String>> res = new List<List<String>>();
		CSVReader reader = new CSVReader(csvString);
		while (reader.it.hasNext()) {
			res.add(reader.it.next());
		}
		return res;
	}
	
	private static String convertLineEndings(String str) {
		return str.replace(CRLF, LF).replace(LFCR, LF).replace(CR, LF);
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
			
			if (!currentValue.startsWith(DQUOTE)) {
				tmpValues.add(currentValue);
				
				if (foundAt == nlAt) {
					break;
				}
				startPos = position;
			}
			else if (currentValue == DQUOTEDQUOTE) {
				tmpValues.add('');
				if (foundAt == nlAt) {
					break;
				}
				startPos = position;
			}
			else if (currentValue.endsWith(DQUOTE)) {
				Integer lastIndex = currentValue.length() - 1;
				currentValue = currentValue.substring(1, lastIndex);
				
				//Does it contain double quoted quotes? I.e. Escaped double quotes
                		Integer doubleQuotedQuotesIndex = currentValue.indexOf(DQUOTEDQUOTE);
                		if(doubleQuotedQuotesIndex >= 0) {
                    			// Replace double quoted quotes with double quotes.
                    			currentValue = currentValue.replace(DQUOTEDQUOTE, DQUOTE);
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
			if (tmpValues[i].indexOf(DQUOTEDQUOTE_REPLACEMENT) >= 0) {
				tmpValues[i] = tmpValues[i].replace(DQUOTEDQUOTE_REPLACEMENT, DQUOTEDQUOTE);
			}
			//APW: Add quotes to fields that need it. source: https://en.wikipedia.org/wiki/Comma-separated_values#Basic_rules
			if (tmpValues[i].indexOf(COMMA) >= 0 || tmpValues[i].indexOf(CR) >= 0 || tmpValues[i].indexOf(LF) >= 0 || (tmpValues[i].indexOf(DQUOTEDQUOTE) >= 0 && tmpValues[i] != DQUOTEDQUOTE) || tmpValues[i].startsWith(SP) || tmpValues[i].endsWith(SP)) {
					tmpValues[i] = '"' + tmpValues[i] + '"';
			}
		}

		values.addAll(tmpValues);
		return position;
	}
}
