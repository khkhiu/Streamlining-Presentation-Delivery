// src/handlers/ChatHandler.js - Complete Implementation
class ChatHandler {
    constructor(config) {
      this.config = config;
      this.messages = [];
      this.dataSources = [];
      this.avatarHandler = config.avatarHandler;
    }
  
    async handleUserQuery(userQuery, userQueryHTML = '', imgUrlPath = '') {
      const chatMessage = this.createChatMessage(userQuery, imgUrlPath);
      this.messages.push(chatMessage);
  
      // Stop any ongoing speech
      if (this.avatarHandler.isSpeaking) {
        await this.avatarHandler.stopSpeaking();
      }
  
      // Handle quick replies if enabled
      if (this.dataSources.length > 0 && this.config.enableQuickReply) {
        await this.handleQuickReply();
      }
  
      try {
        const response = await this.fetchChatResponse(userQuery);
        return await this.processStreamingResponse(response);
      } catch (error) {
        console.error('Error processing chat query:', error);
        throw error;
      }
    }
  
    createChatMessage(userQuery, imgUrlPath) {
      const content = imgUrlPath.trim() 
        ? [
            { type: 'text', text: userQuery },
            { type: 'image_url', image_url: { url: imgUrlPath }}
          ]
        : userQuery;
  
      return {
        role: 'user',
        content: content
      };
    }
  
    async handleQuickReply() {
      const quickReply = this.getQuickReply();
      await this.avatarHandler.speak(quickReply, 2000);
    }
  
    getQuickReply() {
      const { quickReplies } = this.config;
      return quickReplies[Math.floor(Math.random() * quickReplies.length)];
    }
  
    async fetchChatResponse(userQuery) {
      const url = this.buildChatApiUrl();
      const body = this.buildRequestBody();
  
      const response = await fetch(url, {
        method: 'POST',
        headers: {
          'api-key': this.config.azureOpenAIApiKey,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(body)
      });
  
      if (!response.ok) {
        throw new Error(`Chat API response status: ${response.status} ${response.statusText}`);
      }
  
      return response;
    }
  
    async processStreamingResponse(response) {
      let assistantReply = '';
      let toolContent = '';
      let spokenSentence = '';
      const reader = response.body.getReader();
      const decoder = new TextDecoder();
  
      try {
        while (true) {
          const { value, done } = await reader.read();
          if (done) break;
  
          const chunk = decoder.decode(value, { stream: true });
          const lines = chunk.split('\n\n');
  
          for (const line of lines) {
            if (line.startsWith('data:') && !line.endsWith('[DONE]')) {
              const responseJson = JSON.parse(line.substring(5).trim());
              await this.processResponseChunk(responseJson, assistantReply, toolContent, spokenSentence);
            }
          }
        }
  
        // Handle any remaining spoken sentence
        if (spokenSentence) {
          await this.avatarHandler.speak(spokenSentence);
        }
  
        // Add messages to conversation history
        if (this.dataSources.length > 0 && toolContent) {
          this.messages.push({ role: 'tool', content: toolContent });
        }
  
        this.messages.push({ role: 'assistant', content: assistantReply });
  
        return { assistantReply, toolContent };
  
      } catch (error) {
        console.error('Error processing streaming response:', error);
        throw error;
      }
    }
  
    async processResponseChunk(responseJson, assistantReply, toolContent, spokenSentence) {
      let responseToken;
      
      if (this.dataSources.length === 0) {
        responseToken = responseJson.choices[0].delta.content;
      } else {
        const role = responseJson.choices[0].messages[0].delta.role;
        if (role === 'tool') {
          toolContent = responseJson.choices[0].messages[0].delta.content;
        } else {
          responseToken = responseJson.choices[0].messages[0].delta.content;
          if (responseToken) {
            responseToken = responseToken.replace(this.config.byodDocRegex, '').trim();
            if (responseToken === '[DONE]') {
              responseToken = undefined;
            }
          }
        }
      }
  
      if (responseToken) {
        assistantReply += responseToken;
        spokenSentence += responseToken;
  
        if (responseToken === '\n' || responseToken === '\n\n') {
          await this.avatarHandler.speak(spokenSentence);
          spokenSentence = '';
        } else {
          const punctuationMatch = this.config.sentenceLevelPunctuations
            .find(punct => responseToken.includes(punct));
          
          if (punctuationMatch) {
            await this.avatarHandler.speak(spokenSentence);
            spokenSentence = '';
          }
        }
      }
    }
  
    buildChatApiUrl() {
      const { azureOpenAIEndpoint, azureOpenAIDeploymentName } = this.config;
      const baseUrl = this.dataSources.length > 0
        ? `${azureOpenAIEndpoint}/openai/deployments/${azureOpenAIDeploymentName}/extensions/chat/completions`
        : `${azureOpenAIEndpoint}/openai/deployments/${azureOpenAIDeploymentName}/chat/completions`;
      
      return `${baseUrl}?api-version=2023-06-01-preview`;
    }
  
    buildRequestBody() {
      const body = {
        messages: this.messages,
        stream: true
      };
  
      if (this.dataSources.length > 0) {
        body.dataSources = this.dataSources;
      }
  
      return body;
    }
  
    setDataSources(cogSearchConfig) {
      const dataSource = {
        type: 'AzureCognitiveSearch',
        parameters: {
          endpoint: cogSearchConfig.endpoint,
          key: cogSearchConfig.key,
          indexName: cogSearchConfig.indexName,
          semanticConfiguration: '',
          queryType: 'simple',
          fieldsMapping: {
            contentFieldsSeparator: '\n',
            contentFields: ['content'],
            filepathField: null,
            titleField: 'title',
            urlField: null
          },
          inScope: true,
          roleInformation: this.config.prompt
        }
      };
  
      this.dataSources = [dataSource];
    }
  }