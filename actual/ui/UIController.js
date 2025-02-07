// ui/UIController.js
export class UIController {
    constructor(avatarService) {
        this.avatarService = avatarService;
        this.previousAnimationFrameTimestamp = 0;
    }
    
    setupListeners() {
        document.getElementById('startSession').addEventListener('click', () => this.handleStartSession());
        document.getElementById('speak').addEventListener('click', () => this.handleSpeak());
        document.getElementById('stopSpeaking').addEventListener('click', () => this.handleStopSpeaking());
        document.getElementById('stopSession').addEventListener('click', () => this.handleStopSession());
        document.getElementById('transparentBackground').addEventListener('change', () => this.handleTransparentBackground());
        document.getElementById('enablePrivateEndpoint').addEventListener('change', () => this.handlePrivateEndpoint());
    }
    
    updateUI(state) {
        const elements = {
            speak: document.getElementById('speak'),
            stopSpeaking: document.getElementById('stopSpeaking'),
            stopSession: document.getElementById('stopSession'),
            startSession: document.getElementById('startSession'),
            configuration: document.getElementById('configuration')
        };
        
        Object.entries(state).forEach(([elementId, value]) => {
            if (elements[elementId]) {
                if (typeof value === 'boolean') {
                    elements[elementId].disabled = !value;
                } else if (typeof value === 'string') {
                    elements[elementId].hidden = value === 'hidden';
                }
            }
        });
    }
}