public with sharing class OpenAICallout {
    public class OpenAIRequest {
        @AuraEnabled public String prompt;
        @AuraEnabled public String useCase;
    }

    public class OpenAIResponse {
        @AuraEnabled public Boolean success;
        @AuraEnabled public String responseText;
        @AuraEnabled public String errorMessage;
        @AuraEnabled public Integer statusCode;
    }

    @AuraEnabled
    public static OpenAIResponse generateServiceResponse(String recordId, String prompt) {
        OpenAIRequest request = new OpenAIRequest();
        request.prompt = prompt;
        request.useCase = 'service_assistant';
        return generateResponse(request);
    }

    @AuraEnabled
    public static OpenAIResponse generateResponse(OpenAIRequest request) {
        validateRequest(request);
        if (Limits.getCallouts() >= Limits.getLimitCallouts()) {
            throw new AuraHandledException('Callout limit reached before OpenAI request could be sent.');
        }

        HttpRequest httpRequest = new HttpRequest();
        httpRequest.setEndpoint('callout:OpenAI_API/v1/responses');
        httpRequest.setMethod('POST');
        httpRequest.setHeader('Content-Type', 'application/json');
        httpRequest.setTimeout(20000);
        httpRequest.setBody(JSON.serialize(new Map<String, Object>{
            'model' => 'gpt-4.1-mini',
            'input' => new List<Object>{
                new Map<String, Object>{
                    'role' => 'system',
                    'content' => 'You are a Salesforce assistant. Return concise, grounded guidance and avoid unsupported claims.'
                },
                new Map<String, Object>{
                    'role' => 'user',
                    'content' => request.prompt
                }
            },
            'metadata' => new Map<String, Object>{ 'use_case' => request.useCase }
        }));

        HttpResponse httpResponse = new Http().send(httpRequest);
        return parseResponse(httpResponse);
    }

    private static void validateRequest(OpenAIRequest request) {
        if (request == null || String.isBlank(request.prompt)) {
            throw new AuraHandledException('Prompt is required for OpenAI callout.');
        }
        if (request.prompt.length() > 12000) {
            throw new AuraHandledException('Prompt exceeds configured safety limit.');
        }
    }

    private static OpenAIResponse parseResponse(HttpResponse httpResponse) {
        OpenAIResponse response = new OpenAIResponse();
        response.statusCode = httpResponse.getStatusCode();
        response.success = response.statusCode >= 200 && response.statusCode < 300;
        if (!response.success) {
            response.errorMessage = 'OpenAI API returned HTTP ' + response.statusCode + ': ' + httpResponse.getBody();
            return response;
        }

        Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(httpResponse.getBody());
        if (payload.containsKey('output_text')) {
            response.responseText = String.valueOf(payload.get('output_text'));
        } else {
            response.responseText = JSON.serializePretty(payload);
        }
        return response;
    }
}
