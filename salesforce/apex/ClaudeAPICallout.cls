public with sharing class ClaudeAPICallout {
    public class ClaudeMessageRequest {
        @AuraEnabled public String prompt;
        @AuraEnabled public String systemInstruction;
        @AuraEnabled public Integer maxTokens;
    }

    public class ClaudeMessageResponse {
        @AuraEnabled public Boolean success;
        @AuraEnabled public String responseText;
        @AuraEnabled public String errorMessage;
        @AuraEnabled public Integer statusCode;
    }

    @AuraEnabled
    public static ClaudeMessageResponse generateResponse(ClaudeMessageRequest request) {
        validateRequest(request);
        if (Limits.getCallouts() >= Limits.getLimitCallouts()) {
            throw new AuraHandledException('Callout limit reached before Claude request could be sent.');
        }

        HttpRequest httpRequest = new HttpRequest();
        httpRequest.setEndpoint('callout:Anthropic_API/v1/messages');
        httpRequest.setMethod('POST');
        httpRequest.setHeader('Content-Type', 'application/json');
        httpRequest.setHeader('anthropic-version', '2023-06-01');
        httpRequest.setTimeout(20000);
        httpRequest.setBody(JSON.serialize(new Map<String, Object>{
            'model' => 'claude-3-5-sonnet-latest',
            'max_tokens' => request.maxTokens == null ? 700 : request.maxTokens,
            'system' => request.systemInstruction,
            'messages' => new List<Object>{
                new Map<String, Object>{ 'role' => 'user', 'content' => request.prompt }
            }
        }));

        HttpResponse httpResponse = new Http().send(httpRequest);
        return parseResponse(httpResponse);
    }

    private static void validateRequest(ClaudeMessageRequest request) {
        if (request == null || String.isBlank(request.prompt)) {
            throw new AuraHandledException('Prompt is required for Claude callout.');
        }
        if (request.prompt.length() > 12000) {
            throw new AuraHandledException('Prompt exceeds configured safety limit.');
        }
    }

    private static ClaudeMessageResponse parseResponse(HttpResponse httpResponse) {
        ClaudeMessageResponse response = new ClaudeMessageResponse();
        response.statusCode = httpResponse.getStatusCode();
        response.success = response.statusCode >= 200 && response.statusCode < 300;

        if (!response.success) {
            response.errorMessage = 'Claude API returned HTTP ' + response.statusCode + ': ' + httpResponse.getBody();
            return response;
        }

        Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(httpResponse.getBody());
        List<Object> contentItems = (List<Object>) payload.get('content');
        List<String> textParts = new List<String>();
        if (contentItems != null) {
            for (Object item : contentItems) {
                Map<String, Object> contentItem = (Map<String, Object>) item;
                if (contentItem.get('text') != null) {
                    textParts.add(String.valueOf(contentItem.get('text')));
                }
            }
        }
        response.responseText = String.join(textParts, '\n');
        return response;
    }
}
