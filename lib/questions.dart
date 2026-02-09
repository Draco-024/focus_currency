import 'dart:math';

class Question {
  final String text;
  final List<String> options;
  final int correctIndex;
  final String subject;
  final int reward;

  Question({
    required this.text,
    required this.options,
    required this.correctIndex,
    required this.subject,
    this.reward = 5,
  });
}

class QuestionGenerator {
  static final Random _rnd = Random();

  static Question next() {
    int type = _rnd.nextInt(3); // 0: Quants, 1: Reasoning, 2: English
    if (type == 0) return _generateQuants();
    if (type == 1) return _generateReasoning();
    return _generateEnglish();
  }

  // 1. QUANTS
  static Question _generateQuants() {
    int subType = _rnd.nextInt(5); 

    if (subType == 0) {
      double base = (_rnd.nextInt(800) + 100) + 0.89;
      int pct = _rnd.nextInt(80) + 10;
      int extra = _rnd.nextInt(50) + 20;
      int ans = ((base.round() * pct) / 100).round() + extra;
      return _buildMathQ("Approx: $pct% of ${base.toStringAsFixed(2)} + $extra = ?", ans, "Quants", 5);
    } else if (subType == 1) {
      int start = _rnd.nextInt(10) + 5;
      List<int> s = [start];
      double mult = 0.5;
      for(int i=0; i<4; i++) {
        int nextVal = (s.last * mult).toInt() + (i+1);
        s.add(nextVal);
        mult += 0.5;
      }
      return _buildMathQ("Series: ${s[0]}, ${s[1]}, ${s[2]}, ${s[3]}, ?", s[4], "Quants", 8);
    } else if (subType == 2) {
      int r1 = _rnd.nextInt(15) + 5; 
      int r2 = _rnd.nextInt(15) + 5; 
      int sum = r1 + r2;
      int prod = r1 * r2;
      List<String> opts = ["$r1, $r2", "${r1+2}, ${r2+2}", "-$r1, -$r2", "No relation"];
      opts.shuffle();
      return Question(text: "Solve: x² - ${sum}x + $prod = 0", options: opts, correctIndex: opts.indexOf("$r1, $r2"), subject: "Quants", reward: 10);
    } else if (subType == 3) {
      int a = _rnd.nextInt(10) + 10;
      int b = a * 2; 
      return _buildMathQ("A does work in $a days. B is half as efficient as A. Together?", (a * 2 * a) ~/ (a + 2 * a), "Quants", 8);
    } else {
      int ratioA = 3 + _rnd.nextInt(3);
      int ratioB = 2 + _rnd.nextInt(2);
      int multiplier = 5 + _rnd.nextInt(5);
      int ageA = ratioA * multiplier;
      int ageB = ratioB * multiplier;
      return _buildMathQ("Ratio of ages A:B is $ratioA:$ratioB. Sum is ${ageA+ageB}. A's age after 5 years?", ageA + 5, "Quants", 5);
    }
  }

  static Question _buildMathQ(String text, int ans, String subject, int reward) {
    Set<int> opts = {ans};
    while(opts.length < 4) {
      int wrong = ans + (_rnd.nextInt(20) - 10);
      if(wrong != ans && wrong > 0) opts.add(wrong);
    }
    List<String> options = opts.map((e) => e.toString()).toList();
    options.shuffle();
    return Question(text: text, options: options, correctIndex: options.indexOf(ans.toString()), subject: subject, reward: reward);
  }

  // 2. REASONING
  static Question _generateReasoning() {
    int t = _rnd.nextInt(4);
    if(t == 0) {
      List<String> p = ["A","B","C","D","E","F"];
      p.shuffle();
      return Question(text: "Inequality: L > M ≥ N < O = P ≤ Q.\nConclusion: L > N", options: ["True", "False", "Either Or", "Can't Say"], correctIndex: 0, subject: "Reasoning", reward: 5);
    }
    if(t == 1) {
      return Question(text: "Point to a man, a lady said 'He is the father of my mother's only son'. How is the man related to the lady?", options: ["Uncle", "Father", "Grandfather", "Brother"], correctIndex: 0, subject: "Reasoning", reward: 5);
    }
    if(t == 2) {
      int shift = _rnd.nextInt(3) + 1; 
      String word = "BANK";
      String code = "";
      for(int i=0; i<word.length; i++) code += String.fromCharCode(word.codeUnitAt(i) + shift);
      String qWord = "PO";
      String ans = "";
      for(int i=0; i<qWord.length; i++) ans += String.fromCharCode(qWord.codeUnitAt(i) + shift);
      List<String> opts = [ans, "QP", "QR", "RS"];
      if(!opts.contains("QP")) opts.add("QP"); 
      opts.shuffle();
      return Question(text: "If $word is coded as $code, how is $qWord coded?", options: opts, correctIndex: opts.indexOf(ans), subject: "Reasoning", reward: 5);
    }
    return Question(text: "Statements: Only a few Pink are Red. All Red are Blue.\nConclusion: All Pink can never be Blue.", options: ["Follows", "Does not Follow", "Either Or", "None"], correctIndex: 1, subject: "Reasoning", reward: 6);
  }

  // 3. ENGLISH
  static Question _generateEnglish() {
    List<Question> bank = [
      Question(text: "Synonym: EPHEMERAL", options: ["Transient", "Permanent", "Eternal", "Stable"], correctIndex: 0, subject: "English"),
      Question(text: "Synonym: ALACRITY", options: ["Laziness", "Eagerness", "Doubt", "Fear"], correctIndex: 1, subject: "English"),
      Question(text: "Antonym: GREGARIOUS", options: ["Sociable", "Introvert", "Friendly", "Talkative"], correctIndex: 1, subject: "English"),
      Question(text: "Synonym: OBSEQUIOUS", options: ["Domineering", "Servile", "Honest", "Brave"], correctIndex: 1, subject: "English"),
      Question(text: "Antonym: CACOPHONY", options: ["Noise", "Harmony", "Discord", "Shout"], correctIndex: 1, subject: "English"),
      Question(text: "Synonym: PERNICIOUS", options: ["Harmful", "Beneficial", "Kind", "Helpful"], correctIndex: 0, subject: "English"),
      Question(text: "Synonym: LACONIC", options: ["Verbose", "Concise", "Loud", "Rude"], correctIndex: 1, subject: "English"),
      Question(text: "Antonym: ZENITH", options: ["Peak", "Nadir", "Top", "Summit"], correctIndex: 1, subject: "English"),
      Question(text: "Synonym: CANDID", options: ["Frank", "Secretive", "Biased", "Cruel"], correctIndex: 0, subject: "English"),
      Question(text: "Idiom: 'To grease the palm'", options: ["To work hard", "To bribe", "To cook", "To fight"], correctIndex: 1, subject: "English"),
      Question(text: "Idiom: 'A white elephant'", options: ["Rare item", "Costly but useless", "Peace symbol", "Strong person"], correctIndex: 1, subject: "English"),
      Question(text: "Idiom: 'To sit on the fence'", options: ["To be lazy", "Undecided", "To defend", "To attack"], correctIndex: 1, subject: "English"),
      Question(text: "Idiom: 'Bolt from the blue'", options: ["Sudden shock", "Pleasant surprise", "Heavy rain", "Blue sky"], correctIndex: 0, subject: "English"),
      Question(text: "Error: One of the boy / was missing / from the class.", options: ["One of the boy", "was missing", "from the class", "No Error"], correctIndex: 0, subject: "English"), 
      Question(text: "Error: Neither he nor his friends / is going / to the party.", options: ["Neither he", "is going", "to the party", "No Error"], correctIndex: 1, subject: "English"), 
      Question(text: "Error: The police / has arrested / the thief.", options: ["The police", "has arrested", "the thief", "No Error"], correctIndex: 1, subject: "English"), 
      Question(text: "Error: He is / senior than / me.", options: ["He is", "senior than", "me", "No Error"], correctIndex: 1, subject: "English"), 
      Question(text: "Error: I prefer / tea / than coffee.", options: ["I prefer", "tea", "than coffee", "No Error"], correctIndex: 2, subject: "English"), 
      Question(text: "Filler: The rich should not look ___ upon the poor.", options: ["up", "down", "after", "into"], correctIndex: 1, subject: "English"),
      Question(text: "Filler: She is good ___ Mathematics.", options: ["in", "at", "on", "with"], correctIndex: 1, subject: "English"),
      Question(text: "Filler: He died ___ cancer.", options: ["from", "of", "by", "with"], correctIndex: 1, subject: "English"),
      Question(text: "Select Correct Spelling:", options: ["Embarass", "Embarrass", "Embaras", "Emmbarass"], correctIndex: 1, subject: "English"),
      Question(text: "Select Correct Spelling:", options: ["Occurred", "Occured", "Ocurred", "Occurrad"], correctIndex: 0, subject: "English"),
    ];
    return bank[_rnd.nextInt(bank.length)];
  }
}