import json
import pandas as pd

def generate_english_training_data():
    training_data = []
    
    # Grammar training examples
    grammar_examples = [
        {
            "input": "Explain present simple tense",
            "output": "The Present Simple tense is used for:\n\n1. Habits and routines: \"I work every day.\"\n2. General truths: \"The sun rises in the east.\"\n3. Permanent situations: \"She lives in London.\"\n\nStructure:\n- I/You/We/They: base verb (work)\n- He/She/It: base verb + s (works)\n\nTime expressions: always, usually, often, every day, never"
        },
        {
            "input": "What's the difference between present simple and present continuous?",
            "output": "Present Simple vs Present Continuous:\n\n📚 PRESENT SIMPLE:\n- Habits & routines: \"I work every day.\"\n- General truths: \"Water boils at 100°C.\"\n- Permanent situations: \"He lives in Paris.\"\n\n🎯 PRESENT CONTINUOUS:\n- Actions happening now: \"I'm studying English.\"\n- Temporary situations: \"She's staying at a hotel.\"\n- Future arrangements: \"We're meeting tomorrow.\"\n\nKey difference: Permanent vs Temporary, Habit vs Current Action"
        }
    ]
    
    # Pronunciation training examples
    pronunciation_examples = [
        {
            "input": "How to pronounce 'water'?",
            "output": "🎯 Pronunciation: \"water\"\n\n📝 Phonetic: /ˈwɔːtər/ (US) or /ˈwɒtə/ (UK)\n💡 Key Tips:\n- American: \"wader\" (flap T sounds like D)\n- British: \"waw-tuh\" (clear T sound)\n- Stress on first syllable: WA-ter\n\n🎤 Practice:\n- \"Can I have some water, please?\"\n- \"The water is very cold.\"\n- \"I drink water every day.\""
        },
        {
            "input": "Help with TH sound",
            "output": "🔊 Mastering the TH Sound\n\nTwo types of TH sounds:\n\n1. Voiceless TH (/θ/):\n- \"think\", \"thank\", \"three\", \"birthday\"\n- Tongue between teeth, no vocal vibration\n\n2. Voiced TH (/ð/):\n- \"this\", \"that\", \"mother\", \"brother\"\n- Tongue between teeth, with vocal vibration\n\n🎯 Practice Exercises:\n- \"Three thin thinkers thinking thoroughly\"\n- \"This is better than that\"\n- \"Their mother's birthday is on Thursday\""
        }
    ]
    
    # Vocabulary training examples
    vocabulary_examples = [
        {
            "input": "Business English vocabulary",
            "output": "💼 Essential Business English Vocabulary:\n\n📊 Meetings:\n- Agenda: meeting plan\n- Minutes: written record\n- Action items: tasks to complete\n- Deadline: due date\n\n📈 Performance:\n- KPI: Key Performance Indicator\n- ROI: Return on Investment\n- Benchmark: standard for comparison\n- Target: goal to achieve\n\n💬 Useful Phrases:\n- \"Let's circle back to that\"\n- \"I'll follow up on that\"\n- \"What's the timeline?\"\n- \"Let's touch base tomorrow\""
        }
    ]
    
    # Combine all training data
    training_data.extend(grammar_examples)
    training_data.extend(pronunciation_examples)
    training_data.extend(vocabulary_examples)
    
    return training_data

def save_training_data():
    data = generate_english_training_data()
    
    # Save as JSONL for fine-tuning
    with open('english_training_data.jsonl', 'w') as f:
        for item in data:
            f.write(json.dumps(item) + '\n')
    
    # Save as CSV for reference
    df = pd.DataFrame(data)
    df.to_csv('english_training_data.csv', index=False)
    
    print(f"Generated {len(data)} training examples")
    print("Files saved: english_training_data.jsonl, english_training_data.csv")

if __name__ == "__main__":
    save_training_data()