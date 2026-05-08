public with sharing class CRMPromptBuilder {
    public static String buildLeadScoringPrompt(Lead leadRecord) {
        if (leadRecord == null) {
            throw new AuraHandledException('Lead is required.');
        }
        return String.join(new List<String>{
            'Assess this lead using fit, intent, urgency, and data quality.',
            'Return JSON with score, rating, rationale, and recommended_next_step.',
            'Do not infer protected attributes or use unavailable customer data.',
            'Lead Source: ' + valueOrUnknown(leadRecord.LeadSource),
            'Industry: ' + valueOrUnknown(leadRecord.Industry),
            'Company: ' + valueOrUnknown(leadRecord.Company),
            'Annual Revenue: ' + valueOrUnknown(String.valueOf(leadRecord.AnnualRevenue)),
            'Employees: ' + valueOrUnknown(String.valueOf(leadRecord.NumberOfEmployees))
        }, '\n');
    }

    public static String buildCaseSummaryPrompt(Case caseRecord) {
        if (caseRecord == null) {
            throw new AuraHandledException('Case is required.');
        }
        return String.join(new List<String>{
            'Summarize this Service Cloud case for an agent handoff.',
            'Include customer issue, known facts, attempted resolution, sentiment, risk, and next action.',
            'Avoid adding facts that are not present in the CRM fields.',
            'Subject: ' + valueOrUnknown(caseRecord.Subject),
            'Status: ' + valueOrUnknown(caseRecord.Status),
            'Priority: ' + valueOrUnknown(caseRecord.Priority),
            'Description: ' + valueOrUnknown(caseRecord.Description)
        }, '\n');
    }

    public static String buildNextBestActionPrompt(Opportunity opportunityRecord, Account accountRecord) {
        if (opportunityRecord == null || accountRecord == null) {
            throw new AuraHandledException('Opportunity and Account are required.');
        }
        return String.join(new List<String>{
            'Recommend the next best seller action for this opportunity.',
            'Return action, reason, confidence, required_human_review, and suggested_talk_track.',
            'Respect pricing governance and do not propose discounts without approval.',
            'Account Industry: ' + valueOrUnknown(accountRecord.Industry),
            'Opportunity Stage: ' + valueOrUnknown(opportunityRecord.StageName),
            'Amount: ' + valueOrUnknown(String.valueOf(opportunityRecord.Amount)),
            'Close Date: ' + valueOrUnknown(String.valueOf(opportunityRecord.CloseDate)),
            'Probability: ' + valueOrUnknown(String.valueOf(opportunityRecord.Probability))
        }, '\n');
    }

    private static String valueOrUnknown(String value) {
        return String.isBlank(value) || value == 'null' ? 'Unknown' : value;
    }
}
