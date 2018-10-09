require 'sqlite3'
require 'singleton'


class QuestionsDatabase < SQLite3::Database
  include Singleton

  def initialize
    super('questions.db')
    self.type_translation = true
    self.results_as_hash = true
  end
end






class User
  attr_accessor :fname, :lname

  def initialize(options)
    @id = options['id']
    @fname = options['fname']
    @lname = options['lname']
  end

  def save
    if @id.nil?
      QuestionsDatabase.instance.execute(<<-SQL, @fname, @lname)
        INSERT INTO
          users (fname, lname)
        VALUES
          (?, ?)
      SQL
      @id = QuestionsDatabase.instance.last_insert_row_id
    else
      QuestionsDatabase.instance.execute(<<-SQL, @fname, @lname, @id)
        UPDATE
          users
        SET
          fname = ?, lname = ?
        WHERE
          id = ?
      SQL
    end
  end

  def average_karma
    karma = QuestionsDatabase.instance.execute(<<-SQL, @id)
      SELECT
        users.id, users.fname, users.lname,
        COUNT(DISTINCT(questions.id)) AS TOTAL_QUESTIONS,
        COUNT(question_likes.id) AS TOTAL_LIKES,
        CAST(COUNT(question_likes.id) AS FLOAT) / COUNT(DISTINCT(questions.id)) AS AVG_KARMA
      FROM
        users
      JOIN
        questions ON users.id = questions.author_id
      LEFT JOIN
        question_likes ON question_likes.question_id = questions.id
      WHERE
        users.id = ?
      GROUP BY
        users.id
    SQL

    karma.first['AVG_KARMA']
  end

  def liked_questions
    QuestionLike.liked_questions_for_user_id(@id)
  end

  def followed_questions
    QuestionFollow.followed_questions_for_user_id(@id)
  end

  def self.find_by_id(id)
    user = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        users
      WHERE
        id = ?
  SQL
  User.new(user.first)
  end

  def self.find_by_name(fname, lname)
    user = QuestionsDatabase.instance.execute(<<-SQL, fname, lname)
      SELECT
        *
      FROM
        users
      WHERE
        fname = ? AND
        lname = ?
  SQL
  User.new(user.first)
  end

  def authored_questions
    Question.find_by_author_id(@id)
  end

  def authored_replies
    Reply.find_by_user_id(@id)
  end
end





class Question

  attr_accessor :id, :title, :body, :author_id

  def initialize(options)
    @id = options['id']
    @title = options['title']
    @body = options['body']
    @author_id = options['author_id']
  end

  def save
    if @id.nil?
      QuestionsDatabase.instance.execute(<<-SQL, @title, @body, @author_id)
        INSERT INTO
          questions (title, body, author_id)
        VALUES
          (?, ?, ?)
      SQL
      @id = QuestionsDatabase.instance.last_insert_row_id
    else
      QuestionsDatabase.instance.execute(<<-SQL, @title, @body, @author_id, @id)
        UPDATE
          questions
        SET
          title = ?, body = ?, author_id = ?
        WHERE
          id = ?
      SQL
    end
  end

  def self.most_liked(n)
    QuestionLike.most_liked_questions(n)
  end

  def likers
    QuestionLike.likers_for_question_id(@id)
  end

  def num_likes
    QuestionLike.num_likes_for_question_id(@id)
  end

  def self.most_followed(n)
    QuestionFollow.most_followed_questions(n).first
  end

  def followers
    QuestionFollow.followers_for_question_id(@id)
  end

  def self.find_by_id(id)
    question = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        questions
      WHERE
        id = ?
    SQL
    Question.new(question.first)
  end

  def self.find_by_author_id(author_id)
    quother = QuestionsDatabase.instance.execute(<<-SQL, author_id)
      SELECT
        *
      FROM
        questions
      WHERE
        author_id = ?
    SQL
    quother.map { |quoth| Question.new(quoth) }
  end

  def author
    User.find_by_id(@author_id)
  end

  def replies
    Reply.find_by_question_id(@id)
  end
end





class QuestionFollow

  def initialize(options)
    @id = options['id']
    @user_id = options['user_id']
    @question_id = options['question_id']
  end

  def self.most_followed_questions(n)
    most_followed = QuestionsDatabase.instance.execute(<<-SQL, n)
      SELECT
        question_id, COUNT(user_id) AS followers
      FROM
        question_follows
      GROUP BY
        question_id
      ORDER BY
        followers DESC
      LIMIT
        ?
    SQL

    most_followed.map { |m| Question.find_by_id(m['question_id'])}
  end

  def self.followers_for_question_id(question_id)
    q_follows = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT
        *
      FROM
        question_follows
      JOIN
        questions
        ON questions.id = question_follows.question_id
      JOIN
        users AS users_who_asked
        ON users_who_asked.id = question_follows.user_id
      WHERE
        question_id = ?
    SQL
    q_follows.map { |q| User.find_by_id(q['user_id']) }
  end

  def self.followed_questions_for_user_id(user_id)
    q_followed = QuestionsDatabase.instance.execute(<<-SQL, user_id)
    SELECT
      *
    FROM
      question_follows
    JOIN
      questions
      ON questions.id = question_follows.question_id
    WHERE
      user_id = ?
    SQL
    q_followed.map {|q| Question.find_by_id(q['question_id'])}
  end

  def self.find_by_id(id)
    questionFollow = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        question_follows
      WHERE
        id = ?
    SQL
    QuestionFollow.new(questionFollow.first)
  end
end





class Reply
  def initialize(options)
    @id = options['id']
    @question_id = options['question_id']
    @parent_id = options['parent_id']
    @user_id = options['user_id']
    @body = options['body']
  end

  def save
    if @id.nil?
      QuestionsDatabase.instance.execute(<<-SQL, @question_id, @parent_id, @user_id, @body)
        INSERT INTO
          replies (question_id, parent_id, user_id, body)
        VALUES
          (?, ?, ?, ?)
      SQL
      @id = QuestionsDatabase.instance.last_insert_row_id
    else
      QuestionsDatabase.instance.execute(<<-SQL, @question_id, @parent_id, @user_id, @body, @id)
        UPDATE
          users
        SET
          question_id = ?, parent_id = ?, user_id = ?, body = ?
        WHERE
          id = ?
      SQL
    end
  end

  def author
    User.find_by_id(@user_id)
  end

  def question
    Question.find_by_id(@question_id)
  end

  def parent_reply
    Reply.find_by_id(@parent_id)
  end

  def child_replies
    reply = QuestionsDatabase.instance.execute(<<-SQL, @id)
    SELECT
      *
    FROM
      replies
    WHERE
      parent_id = ?
    SQL
    reply.map {|rep| Reply.new(rep) }
  end


  def self.find_by_id(id)
    reply = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        replies
      WHERE
        id = ?
    SQL
    Reply.new(reply.first)
  end

  def self.find_by_user_id(user_id)
    reply = QuestionsDatabase.instance.execute(<<-SQL, user_id)
      SELECT
        *
      FROM
        replies
      WHERE
        user_id = ?
    SQL
    Reply.new(reply.first)
  end

  def self.find_by_question_id(question_id)
    reply = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT
        *
      FROM
        replies
      WHERE
        question_id = ?
    SQL
    reply.map {|rep| Reply.new(rep) }
  end
end





class QuestionLike
  def initialize(options)
    @id = options['id']
    @user_id = options['user_id']
    @question_id = options['question_id']
  end

  def self.most_liked_questions(n)
    most_liked = QuestionsDatabase.instance.execute(<<-SQL, n)
    SELECT
      question_id, COUNT(user_id) as counted_users
    FROM
      question_likes
    GROUP BY
      question_id
    ORDER BY
      COUNT(user_id) DESC
    LIMIT
      ?
    SQL

    most_liked.map { |m_like| Question.find_by_id(m_like['question_id']) }

  end

  def self.likers_for_question_id(question_id)
    questionLikers = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT
        *
      FROM
        question_likes
      WHERE
        question_id = ?
    SQL
    questionLikers.map {|user| User.find_by_id(user['user_id'])}
  end

  def self.find_by_id(id)
    questionLike = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        question_likes
      WHERE
        id = ?
    SQL
    QuestionLike.new(questionLike.first)
  end

  def self.num_likes_for_question_id(question_id)
    num = QuestionsDatabase.instance.execute(<<-SQL, question_id)
    SELECT
      COUNT(user_id) AS count
    FROM
      question_likes
    WHERE
      question_id = ?
    GROUP BY
      question_id

    SQL
    num.first['count']
  end

  def self.liked_questions_for_user_id(user_id)
    user_likes = QuestionsDatabase.instance.execute(<<-SQL, user_id)
      SELECT
        *
      FROM
        question_likes
      WHERE
        user_id = ?
    SQL

    user_likes.map { |liked| Question.find_by_id(liked['question_id']) }
  end
end
