import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  String _currentContext = 'general';

  // Enhanced API configuration
  static const String geminiApiKey = 'AIzaSyAnB27TuZLdeCFMt1oEURsl4ZIWf0UENFg';
  static const String customModelUrl = 'http://localhost:5000/api/chat'; // Your custom trained model

  // Colors
  final Color primaryColor = const Color(0xFF4B39EF);
  final Color secondaryColor = const Color(0xFF39D2C0);
  final Color primaryBackground = const Color(0xFFF1F4F8);
  final Color secondaryBackground = const Color(0xFFFFFFFF);
  final Color primaryText = const Color(0xFF14181B);
  final Color secondaryText = const Color(0xFF57636C);

  // Enhanced pronunciation database
  final Map<String, Map<String, String>> _pronunciationDatabase = {
    'hello': {
      'phonetic': '/həˈloʊ/',
      'tip': 'Stress on the second syllable: he-LLO',
      'practice': 'Say: "Hello, how are you today?"',
      'audio': 'hello_audio.mp3'
    },
    'water': {
      'phonetic': '/ˈwɔːtər/',
      'tip': 'American: "wader", British: "waw-tuh"',
      'practice': 'Practice: "Can I have some water please?"',
      'audio': 'water_audio.mp3'
    },
    'family': {
      'phonetic': '/ˈfæm.ə.li/',
      'tip': 'Three syllables: FAM-i-ly',
      'practice': 'Say: "My family is very important to me."',
      'audio': 'family_audio.mp3'
    },
    'restaurant': {
      'phonetic': '/ˈres.tə.rɑːnt/',
      'tip': 'Stress on first syllable: RES-taurent',
      'practice': 'Practice: "Let\'s meet at the restaurant."',
      'audio': 'restaurant_audio.mp3'
    },
    'entrepreneur': {
      'phonetic': '/ˌɑːn.trə.prəˈnɜːr/',
      'tip': 'French origin, stress on last syllable: en-tre-pre-NEUR',
      'practice': 'Say: "She is a successful entrepreneur."',
      'audio': 'entrepreneur_audio.mp3'
    },
    'pronunciation': {
      'phonetic': '/prəˌnʌn.siˈeɪ.ʃən/',
      'tip': '5 syllables: pro-nun-ci-A-tion',
      'practice': 'Practice: "I need to improve my pronunciation."',
      'audio': 'pronunciation_audio.mp3'
    }
  };

  // Enhanced grammar database
  final Map<String, Map<String, dynamic>> _grammarDatabase = {
    'present_simple': {
      'usage': ['Habits and routines', 'General truths', 'Permanent situations'],
      'structure': 'Subject + base verb (add "s" for he/she/it)',
      'examples': [
        'I work every day.',
        'She speaks English fluently.',
        'The sun rises in the east.'
      ],
      'keywords': ['always', 'usually', 'often', 'every day']
    },
    'present_continuous': {
      'usage': ['Actions happening now', 'Temporary situations', 'Future arrangements'],
      'structure': 'Subject + am/is/are + verb-ing',
      'examples': [
        'I am studying English now.',
        'They are visiting London this week.',
        'She is meeting friends tomorrow.'
      ],
      'keywords': ['now', 'at the moment', 'currently']
    },
    'past_simple': {
      'usage': ['Completed past actions', 'Past habits', 'Specific past times'],
      'structure': 'Subject + past form of verb',
      'examples': [
        'I visited Paris last year.',
        'He finished his homework yesterday.',
        'We played football every day when we were young.'
      ],
      'keywords': ['yesterday', 'last week', 'ago']
    }
  };

  @override
  void initState() {
    super.initState();
    _messages.add(ChatMessage(
      text: "👋 Hello! I'm your AI English Learning Coach!\n\nI can help you with:\n\n📚 Grammar explanations and exercises\n💬 Vocabulary building and idioms\n🎯 Pronunciation practice\n🗣️ Conversation skills\n📝 Writing and speaking practice\n\nWhat would you like to learn today?",
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isLoading) return;

    setState(() {
      _messages.add(ChatMessage(
        text: message,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _messageController.clear();
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      // Try custom trained model first
      final response = await _getCustomModelResponse(message);
      setState(() {
        _messages.add(ChatMessage(
          text: response,
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
    } catch (e) {
      // Fallback to enhanced local responses
      final fallbackResponse = await _getEnhancedLocalResponse(message);
      setState(() {
        _messages.add(ChatMessage(
          text: fallbackResponse,
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
    }

    setState(() {
      _isLoading = false;
    });
    _scrollToBottom();
  }

  Future<String> _getCustomModelResponse(String message) async {
    try {
      final response = await http.post(
        Uri.parse(customModelUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': message,
          'context': _currentContext,
          'user_level': 'intermediate', // You can make this dynamic
          'teaching_focus': _getTeachingFocus(message),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['response'] ?? _getEnhancedLocalResponse(message);
      } else {
        throw Exception('Failed to get response from custom model');
      }
    } catch (e) {
      // Fallback to Gemini AI
      return await _getGeminiResponse(message);
    }
  }

  Future<String> _getGeminiResponse(String message) async {
    if (geminiApiKey.isEmpty) {
      return await _getEnhancedLocalResponse(message);
    }

    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: geminiApiKey,
        generationConfig: GenerationConfig(
          temperature: 0.7,
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 1000,
        ),
      );

      final prompt = _buildEnhancedPrompt(message);
      final response = await model.generateContent([Content.text(prompt)]);

      return response.text ?? await _getEnhancedLocalResponse(message);
    } catch (e) {
      return await _getEnhancedLocalResponse(message);
    }
  }

  String _buildEnhancedPrompt(String userMessage) {
    return """
You are an expert English teacher with specialized training in ESL/EFL education.

CURRENT TEACHING CONTEXT: $_currentContext
USER LEVEL: Intermediate
TEACHING FOCUS: ${_getTeachingFocus(userMessage)}

SPECIALIZED KNOWLEDGE BASE:

PRONUNCIATION GUIDE:
${_pronunciationDatabase.entries.map((e) => "- ${e.key}: ${e.value['phonetic']} - ${e.value['tip']}").join('\n')}

GRAMMAR DATABASE:
${_grammarDatabase.entries.map((e) => "- ${e.key.replaceAll('_', ' ').toUpperCase()}: ${e.value['structure']}").join('\n')}

VOCABULARY CATEGORIES:
- Everyday Conversations
- Business English
- Academic Writing
- Travel & Social Situations
- Idioms & Phrasal Verbs

TEACHING METHODOLOGY:
1. Identify student's specific need from the message
2. Provide clear, structured explanations
3. Include practical examples
4. Offer immediate practice opportunities
5. Give constructive feedback
6. Build confidence through encouragement

USER'S MESSAGE: "$userMessage"

RESPONSE GUIDELINES:
- Be specific and practical
- Use the phonetic database when relevant
- Provide multiple examples
- Include interactive exercises
- Correct common mistakes
- Use encouraging language
- Adapt to intermediate level

Respond as a professional English teacher.
""";
  }

  String _getTeachingFocus(String message) {
    final lowerMessage = message.toLowerCase();
    if (lowerMessage.contains('pronounc')) return 'pronunciation';
    if (lowerMessage.contains('grammar') || lowerMessage.contains('tense')) return 'grammar';
    if (lowerMessage.contains('vocab') || lowerMessage.contains('word')) return 'vocabulary';
    if (lowerMessage.contains('speak') || lowerMessage.contains('conversation')) return 'speaking';
    if (lowerMessage.contains('write')) return 'writing';
    return 'general';
  }

  Future<String> _getEnhancedLocalResponse(String message) async {
    final lowerMessage = message.toLowerCase();
    
    // Update context based on sophisticated pattern matching
    _currentContext = _analyzeMessageContext(lowerMessage);
    
    // Enhanced pronunciation handling
    if (_currentContext == 'pronunciation') {
      return _handlePronunciationQuery(lowerMessage);
    }
    
    // Enhanced grammar handling
    if (_currentContext == 'grammar') {
      return _handleGrammarQuery(lowerMessage);
    }
    
    // Enhanced vocabulary handling
    if (_currentContext == 'vocabulary') {
      return _handleVocabularyQuery(lowerMessage);
    }
    
    // Enhanced practice exercises
    if (_currentContext == 'practice') {
      return _generateInteractiveExercise(lowerMessage);
    }
    
    // Default to comprehensive assistance
    return _getComprehensiveAssistanceResponse(lowerMessage);
  }

  String _analyzeMessageContext(String message) {
    if (message.contains(RegExp(r'pronounc|sound|say|hear'))) return 'pronunciation';
    if (message.contains(RegExp(r'grammar|tense|verb|sentence|structure'))) return 'grammar';
    if (message.contains(RegExp(r'vocab|word|phrase|idiom|expression'))) return 'vocabulary';
    if (message.contains(RegExp(r'practice|exercise|drill|test'))) return 'practice';
    if (message.contains(RegExp(r'speak|talk|conversation|dialog'))) return 'speaking';
    if (message.contains(RegExp(r'write|essay|paragraph|composition'))) return 'writing';
    return 'general';
  }

  String _handlePronunciationQuery(String message) {
    // Check for specific word requests
    for (final word in _pronunciationDatabase.keys) {
      if (message.contains(word)) {
        return _generatePronunciationGuide(word);
      }
    }
    
    // General pronunciation assistance
    return """
🎯 **Pronunciation Practice Center**

I can help you master English pronunciation! Here's what I can do:

**Specific Word Pronunciation:**
${_pronunciationDatabase.keys.map((w) => "• \"How to pronounce $w?\"").join('\n')}

**Sound Patterns:**
- TH sounds (think vs this)
- R vs L sounds
- V vs W sounds
- Word stress patterns
- Sentence rhythm and intonation

**Practice Techniques:**
- Minimal pairs practice
- Tongue twisters
- Shadowing exercises
- Recording and self-analysis

**Just ask about:**
- A specific word: "How do I pronounce 'water'?"
- A sound: "Help with TH sound"
- General tips: "Improve my pronunciation"

Which word or sound would you like to practice? 🎤""";
  }

  String _generatePronunciationGuide(String word) {
    final data = _pronunciationDatabase[word]!;
    return """
🎯 **Pronunciation Guide: "$word"**

📝 **Phonetic Transcription**: ${data['phonetic']}
💡 **Key Tip**: ${data['tip']}
🎤 **Practice Sentence**: "${data['practice']}"

**Step-by-Step Practice:**

1. **Break it down**: ${_breakdownWord(word)}
2. **Common Mistakes**: ${_getCommonMistakes(word)}
3. **Listen & Repeat**: Say it 5 times slowly
4. **Use in Context**: "${_getExampleSentence(word)}"

**Additional Practice Words**:
${_getRelatedPracticeWords(word)}

**Pro Tip**: Record yourself saying the word and compare with native speakers!

Ready to try another word? Just type it! 📚""";
  }

  String _getCommonMistakes(String word) {
  final mistakes = {
    'hello': 'People often say "he-lo" instead of "he-LLO" (stress second syllable).',
    'water': 'In American English, the "t" sounds like a soft "d" — "wa-der".',
    'family': 'Don’t drop the middle syllable: say "FAM-i-ly", not "FAM-ly".',
    'restaurant': 'Don’t pronounce all syllables: say "RES-tront", not "res-tau-rant".',
    'entrepreneur': 'Stress the last syllable: "en-tre-pre-NEUR", not "EN-tre-pre-nor".',
    'pronunciation': 'Common error: saying "proNOUNciation" ❌ instead of "proNUNciation" ✅.',
  };
  return mistakes[word] ?? 'Avoid stressing the wrong syllable or dropping sounds.';
}

String _getExampleSentence(String word) {
  final examples = {
    'hello': 'Hello, how are you today?',
    'water': 'Can I have some water, please?',
    'family': 'My family is going on vacation next week.',
    'restaurant': 'Let’s meet at the new Italian restaurant.',
    'entrepreneur': 'She became a successful entrepreneur at 25.',
    'pronunciation': 'Your pronunciation is getting much better!',
  };
  return examples[word] ?? 'Try using this word in a simple sentence.';
}


  String _breakdownWord(String word) {
    final breakdowns = {
      'hello': 'he-llo (2 syllables)',
      'water': 'wa-ter (2 syllables)',
      'family': 'fam-i-ly (3 syllables)',
      'restaurant': 'res-tau-rant (3 syllables)',
      'entrepreneur': 'en-tre-pre-neur (4 syllables)',
      'pronunciation': 'pro-nun-ci-a-tion (5 syllables)',
    };
    return breakdowns[word] ?? 'Divide into syllables and practice each part';
  }

  String _getRelatedPracticeWords(String word) {
    final related = {
      'hello': '• hi • hey • greeting • welcome',
      'water': '• bottle • better • matter • later',
      'family': '• familiar • familial • famine • famous',
      'restaurant': '• rest • aura • rant • reservation',
    };
    return related[word] ?? '• Practice similar sounding words';
  }

  String _handleGrammarQuery(String message) {
    // Check for specific grammar topics
    if (message.contains('present simple')) {
      return _generateGrammarLesson('present_simple');
    }
    if (message.contains('present continuous') || message.contains('present progressive')) {
      return _generateGrammarLesson('present_continuous');
    }
    if (message.contains('past simple')) {
      return _generateGrammarLesson('past_simple');
    }
    if (message.contains('future')) {
      return _generateFutureTensesLesson();
    }
    
    // General grammar assistance
    return """
📚 **Grammar Learning Center**

I can explain these grammar topics in detail:

**Essential Tenses:**
• Present Simple (habits & facts)
• Present Continuous (actions now)
• Past Simple (completed actions)
• Future Forms (will, going to, present continuous)

**Other Topics:**
• Modal Verbs (can, could, should, must)
• Conditionals (if clauses)
• Prepositions of time and place
• Articles (a, an, the)
• Question Forms
• Passive Voice

**Ask me specific questions like:**
- "Explain Present Simple with examples"
- "Difference between Past Simple and Present Perfect"
- "How to use modal verbs?"
- "Practice exercises for tenses"

Which grammar topic would you like to learn? 📖""";
  }

  String _generateGrammarLesson(String tense) {
    final data = _grammarDatabase[tense]!;
    return """
📚 **${tense.replaceAll('_', ' ').toUpperCase()}**

**When to Use:**
${data['usage'].map((u) => '✅ $u').join('\n')}

**Structure:**
```
${data['structure']}
```

**Examples:**
${data['examples'].map((e) => '• "$e"').join('\n')}

**Common Time Expressions:**
${data['keywords'].map((k) => '• $k').join('\n')}

**Practice Exercise:**
${_generateGrammarExercise(tense)}

**Common Mistakes to Avoid:**
${_getGrammarMistakes(tense)}

**Your Turn:** Create your own sentence using this tense! ✍️""";
  }

  String _generateFutureTensesLesson() {
    return """
📚 **Future Tenses in English**

**1. WILL**
- **Use**: Predictions, spontaneous decisions, promises
- **Structure**: Subject + will + base verb
- **Examples**: 
  • "It will rain tomorrow." (prediction)
  • "I'll help you with that." (spontaneous decision)
  • "I will always love you." (promise)

**2. GOING TO**
- **Use**: Plans, intentions, evidence-based predictions
- **Structure**: Subject + am/is/are + going to + base verb
- **Examples**:
  • "I'm going to study medicine." (plan)
  • "She's going to visit her family." (intention)
  • "Look at those clouds - it's going to rain." (evidence)

**3. PRESENT CONTINUOUS**
- **Use**: Fixed arrangements, appointments
- **Structure**: Subject + am/is/are + verb-ing
- **Examples**:
  • "We're meeting at 6 PM tomorrow." (arrangement)
  • "He's flying to Paris next week." (fixed plan)

**4. PRESENT SIMPLE**
- **Use**: Schedules, timetables
- **Structure**: Subject + base verb
- **Examples**:
  • "The train leaves at 9 AM." (schedule)
  • "The store opens at 8." (timetable)

**Practice:**
Create sentences for:
1. A prediction about the weather
2. Your plans for next weekend
3. A fixed appointment you have
4. A bus or train schedule

Let's see your sentences! 🚀""";
  }

  String _generateGrammarExercise(String tense) {
    final exercises = {
      'present_simple': """
Complete these sentences:
1. I usually ______ (work) from 9 to 5.
2. She ______ (study) English every day.
3. They ______ (live) in London.
4. He ______ (play) football on weekends.

Create your own:
5. I always ______ in the morning.
6. My friend usually ______ after work.""",

      'present_continuous': """
Complete these sentences:
1. I ______ (study) English right now.
2. They ______ (watch) TV at the moment.
3. She ______ (meet) friends later.
4. We ______ (have) dinner now.

Create your own:
5. Right now, I ______.
6. My family ______ this weekend.""",

      'past_simple': """
Complete these sentences:
1. Yesterday I ______ (work) until 6 PM.
2. She ______ (visit) Paris last year.
3. They ______ (play) football yesterday.
4. He ______ (finish) his homework.

Create your own:
5. Last weekend, I ______.
6. Yesterday, my friend ______."""
    };
    
    return exercises[tense] ?? "Create 2 sentences using this tense.";
  }

  String _getGrammarMistakes(String tense) {
    final mistakes = {
      'present_simple': '- Forgetting "s" for he/she/it: "She work" ❌ → "She works" ✅\n- Using continuous for habits: "I am working every day" ❌ → "I work every day" ✅',
      'present_continuous': '- Using for permanent situations: "I am living in London" (if permanent) ❌ → "I live in London" ✅\n- Wrong verb forms: "I am study" ❌ → "I am studying" ✅',
      'past_simple': '- Using present for past: "I go yesterday" ❌ → "I went yesterday" ✅\n- Irregular verbs: "I eated" ❌ → "I ate" ✅',
    };
    return mistakes[tense] ?? '- Practice with common verbs\n- Check time expressions';
  }

  String _handleVocabularyQuery(String message) {
    if (message.contains('idiom')) {
      return """
💬 **English Idioms & Expressions**

**Common Idioms with Examples:**

🍰 **Piece of cake** = Very easy
"The English test was a piece of cake!"

🧊 **Break the ice** = Start a conversation
"He told a funny story to break the ice at the meeting."

💰 **Cost an arm and a leg** = Very expensive
"This new phone cost an arm and a leg."

📚 **Hit the books** = Study hard
"I need to hit the books for my exam tomorrow."

🌧️ **Under the weather** = Feeling sick
"I'm feeling under the weather today."

🤫 **Spill the beans** = Reveal a secret
"Don't spill the beans about the surprise party!"

🚀 **On cloud nine** = Very happy
"She was on cloud nine after hearing the good news."

**Practice:**
Choose 2 idioms and create sentences:

1. 
2. 

Which idioms did you choose? 📝""";
    }
    
    return """
💬 **Vocabulary Building Center**

I can help you expand your English vocabulary in these areas:

**Vocabulary Categories:**
📖 Everyday Conversations
💼 Business English
🎓 Academic Words
✈️ Travel & Social Situations
💡 Idioms & Phrasal Verbs

**Learning Strategies:**
- Learn 5 new words daily
- Use words in context
- Practice with flashcards
- Review regularly

**Ask me about:**
- "Business vocabulary for meetings"
- "Words for describing personality"
- "Academic writing words"
- "Travel phrases"
- "Common phrasal verbs"

**Quick Exercises:**
- Word of the day
- Synonym practice
- Context usage
- Pronunciation practice

What type of vocabulary would you like to learn? 📚""";
  }

  String _generateInteractiveExercise(String message) {
    final exercises = [
      """
📝 **Grammar Practice: Mixed Tenses**

Complete the paragraph with correct tenses:

"Every day, I (1. wake up) ______ at 7 AM. Right now, I (2. study) ______ English. Yesterday, I (3. visit) ______ my friend. Tomorrow, I (4. meet) ______ my teacher."

**Answers:**
1. wake up (Present Simple)
2. am studying (Present Continuous) 
3. visited (Past Simple)
4. am meeting (Present Continuous)

Now create your own mixed tense paragraph! ✍️""",

      """
🎤 **Pronunciation Challenge**

Read these tongue twisters aloud:

1. "She sells seashells by the seashore."
2. "How can a clam cram in a clean cream can?"
3. "I saw a kitten eating chicken in the kitchen."

**Focus on:**
- Clear consonant sounds
- Smooth transitions
- Natural rhythm

Practice each one 3 times! 🗣️""",

      """
💬 **Vocabulary in Context**

Use these words in sentences:

1. **Ambitious** - 
2. **Reliable** -
3. **Efficient** -
4. **Flexible** -

**Example:**
"She is very ambitious and wants to become CEO."

Now write your sentences! 📚""",

      """
🗣️ **Conversation Practice**

Role-play this scenario:

**At a Restaurant**
You: "Good evening, I'd like to make a reservation for two."
Waiter: "Certainly, for what time?"
You: "For 7 PM, please."
Waiter: "Smoking or non-smoking?"
You: "Non-smoking, please."

**Continue the conversation...**
What would you say when ordering food?"""
    ];
    
    // Select exercise based on context or random
    final selectedExercise = exercises[DateTime.now().millisecond % exercises.length];
    
    return """
🎯 **Interactive Practice Session**

$selectedExercise

**Tips for Success:**
- Take your time
- Practice aloud
- Don't worry about mistakes
- Review and improve

Ready for the next exercise? Just ask! 🚀""";
  }

  String _getComprehensiveAssistanceResponse(String message) {
    return """
👋 **English Learning Assistant**

I see you're ready to improve your English! Here's how I can help:

🎯 **Quick Start** (click buttons below)
📚 **Structured Lessons** (ask specific questions)
💬 **Interactive Practice** (exercises & feedback)
🎤 **Personalized Coaching** (focused on your needs)

**Popular Learning Paths:**

1. **Grammar Foundation**
   - Start with Present Simple
   - Practice Past Simple  
   - Learn Future Forms
   - Master all tenses

2. **Pronunciation Mastery**
   - Individual sounds
   - Word stress
   - Sentence rhythm
   - Natural intonation

3. **Vocabulary Building**
   - Essential everyday words
   - Business English
   - Academic vocabulary
   - Idioms and phrases

**Try asking:**
- "Explain Present Simple with examples"
- "How to pronounce 'water' correctly?"
- "Give me a grammar practice exercise"
- "Business English vocabulary"
- "Help with conversation practice"

What would you like to work on first? 😊""";
  }

  // Rest of the UI methods remain the same as your original code...
  void _handleQuickAction(String action) {
    String message = '';
    
    switch (action) {
      case 'Grammar':
        message = 'Explain English grammar rules and give me practice';
        _currentContext = 'grammar';
        break;
      case 'Vocabulary':
        message = 'I want to learn new vocabulary and idioms';
        _currentContext = 'vocabulary';
        break;
      case 'Pronunciation':
        message = 'Help me with English pronunciation practice';
        _currentContext = 'pronunciation';
        break;
      case 'Practice':
        message = 'Give me an interactive practice exercise';
        _currentContext = 'practice';
        break;
      case 'Conversation':
        message = 'Let\'s practice English conversation';
        _currentContext = 'conversation';
        break;
    }
    
    _messageController.text = message;
    _sendMessage();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _clearChat() {
    setState(() {
      _messages.clear();
      _currentContext = 'general';
      _messages.add(ChatMessage(
        text: "👋 Hello! I'm your AI English Learning Coach!\n\nI can help you with:\n\n📚 Grammar explanations and exercises\n💬 Vocabulary building and idioms\n🎯 Pronunciation practice\n🗣️ Conversation skills\n📝 Writing and speaking practice\n\nWhat would you like to learn today?",
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryBackground,
      appBar: AppBar(
        backgroundColor: primaryBackground,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryText),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'AI English Learning Coach',
          style: GoogleFonts.interTight(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: primaryText,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: primaryText),
            onPressed: _clearChat,
            tooltip: 'Clear chat',
          ),
        ],
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildQuickActions(),
          _buildContextIndicator(),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index < _messages.length) {
                  return _buildMessageBubble(_messages[index]);
                } else {
                  return _buildTypingIndicator();
                }
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildQuickActionButton('Grammar', Icons.article, primaryColor),
          _buildQuickActionButton('Vocabulary', Icons.wordpress, Colors.green),
          _buildQuickActionButton('Pronunciation', Icons.record_voice_over, Colors.orange),
          _buildQuickActionButton('Practice', Icons.school, Colors.purple),
          _buildQuickActionButton('Conversation', Icons.chat, Colors.blue),
        ],
      ),
    );
  }

  Widget _buildContextIndicator() {
    if (_currentContext == 'general') return const SizedBox();
    
    final contextColors = {
      'grammar': primaryColor,
      'vocabulary': Colors.green,
      'pronunciation': Colors.orange,
      'practice': Colors.purple,
      'conversation': Colors.blue,
      'speaking': Colors.blue,
      'writing': Colors.brown,
    };
    
    final contextIcons = {
      'grammar': Icons.article,
      'vocabulary': Icons.wordpress,
      'pronunciation': Icons.record_voice_over,
      'practice': Icons.school,
      'conversation': Icons.chat,
      'speaking': Icons.mic,
      'writing': Icons.edit,
    };
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: contextColors[_currentContext]!.withOpacity(0.1),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(contextIcons[_currentContext], size: 16, color: contextColors[_currentContext]),
          const SizedBox(width: 8),
          Text(
            'Teaching: ${_currentContext[0].toUpperCase() + _currentContext.substring(1)}',
            style: TextStyle(
              color: contextColors[_currentContext],
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(String text, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: ElevatedButton.icon(
        onPressed: () => _handleQuickAction(text),
        icon: Icon(icon, size: 16),
        label: Text(text),
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.1),
          foregroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser)
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: secondaryColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.school, color: Colors.white, size: 18),
            ),
          if (!message.isUser) const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: message.isUser ? primaryColor : secondaryBackground,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    message.text,
                    style: GoogleFonts.inter(
                      color: message.isUser ? Colors.white : primaryText,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(message.timestamp),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: secondaryText,
                  ),
                ),
              ],
            ),
          ),
          if (message.isUser) const SizedBox(width: 8),
          if (message.isUser)
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.person, color: primaryColor, size: 18),
            ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: secondaryColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.school, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: secondaryBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(1),
                _buildDot(2),
                _buildDot(3),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return Container(
      width: 8,
      height: 8,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: secondaryText.withOpacity(0.5),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: secondaryBackground,
        border: Border(top: BorderSide(color: secondaryText.withOpacity(0.1))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Ask about English learning...',
                hintStyle: GoogleFonts.inter(color: secondaryText),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: primaryBackground,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(24),
            ),
            child: IconButton(
              onPressed: _sendMessage,
              icon: const Icon(Icons.send, color: Colors.white),
              tooltip: 'Send message',
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}