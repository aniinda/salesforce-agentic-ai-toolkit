import { LightningElement, api } from 'lwc';
import generateServiceResponse from '@salesforce/apex/OpenAICallout.generateServiceResponse';

export default class AiAssistantPanel extends LightningElement {
    @api recordId;

    prompt = '';
    responseText = '';
    errorMessage = '';
    isLoading = false;

    get isGenerateDisabled() {
        return this.isLoading || !this.prompt || this.prompt.trim().length < 5;
    }

    handlePromptChange(event) {
        this.prompt = event.target.value;
    }

    async handleGenerate() {
        this.isLoading = true;
        this.responseText = '';
        this.errorMessage = '';

        try {
            const result = await generateServiceResponse({
                recordId: this.recordId,
                prompt: this.prompt
            });

            if (result.success) {
                this.responseText = this.escapeAndFormat(result.responseText);
            } else {
                this.errorMessage = result.errorMessage || 'The AI service returned an error.';
            }
        } catch (error) {
            this.errorMessage = error?.body?.message || error.message || 'Unexpected error generating AI response.';
        } finally {
            this.isLoading = false;
        }
    }

    escapeAndFormat(value) {
        const escaped = (value || '')
            .replaceAll('&', '&amp;')
            .replaceAll('<', '&lt;')
            .replaceAll('>', '&gt;');
        return escaped.replaceAll('\n', '<br>');
    }
}
