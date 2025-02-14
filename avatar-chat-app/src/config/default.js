// src/config/default.js
module.exports = {
    azure: {
      speech: {
        defaultRegion: 'westus2',
        defaultEndpoint: null
      },
      openai: {
        defaultEndpoint: null,
        apiVersion: '2023-06-01-preview'
      }
    },
    avatar: {
      defaultCharacter: 'lisa',
      defaultStyle: 'casual-sitting'
    },
    features: {
      enableDisplayTextAlignmentWithSpeech: true,
      enableQuickReply: false,
      quickReplies: [
        'Let me take a look.',
        'Let me check.',
        'One moment, please.'
      ]
    }
  };