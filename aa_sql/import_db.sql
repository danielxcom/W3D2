DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS questions;
DROP TABLE IF EXISTS question_follows;
DROP TABLE IF EXISTS replies;
DROP TABLE IF EXISTS question_likes;

PRAGMA foreign_keys = ON;

CREATE TABLE users (
  id INTEGER PRIMARY KEY,
  fname TEXT NOT NULL,
  lname TEXT NOT NULL
);

CREATE TABLE questions (
  id INTEGER PRIMARY KEY,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  author_id INTEGER NOT NULL,

  FOREIGN KEY (author_id) REFERENCES users(id)
);

CREATE TABLE question_follows (
  id INTEGER PRIMARY KEY,
  user_id INTEGER NOT NULL,
  question_id INTEGER NOT NULL,

  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (question_id) REFERENCES questions(id)
);

CREATE TABLE replies (
  id INTEGER PRIMARY KEY,
  question_id INTEGER NOT NULL,
  parent_id INTEGER,
  user_id INTEGER NOT NULL,
  body TEXT NOT NULL,

  FOREIGN KEY (question_id) REFERENCES questions(id),
  FOREIGN KEY (parent_id) REFERENCES replies(id),
  FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE question_likes (
  id INTEGER PRIMARY KEY,
  user_id INTEGER NOT NULL,
  question_id INTEGER NOT NULL,

  FOREIGN KEY (question_id) REFERENCES questions(id),
  FOREIGN KEY (user_id) REFERENCES users(id)
);


INSERT INTO
  users (fname, lname)
VALUES
  ('John', 'Kim'),
  ('Daniel', 'XavierMontaqueEscabez'),
  ('Rebecca', 'Ferguson'),
  ('Tony', 'Montana'),
  ('Marlo', 'Brando');

INSERT INTO
  questions (title, body, author_id)
VALUES
  ('What is the meaning of life?', 'See title im so lost', 2),
  ('What exactly is a potato?', 'I''ve heard of them but never seen one', 1),
  ('Who doth quothed?', 'It is really bad', 1),
  ('Why chicken cross road?','I aneurysm sry',2),
  ('Ruby vs Python?', 'We need answers nooow!', 3),
  ('What is the best trade route for special items?', 'Just asking for a friend', 4),
  ('Where is Littly Italy Town?', 'New York', 5);

INSERT INTO
  question_follows (user_id, question_id)
VALUES
  (2,1),
  (1,2),
  (4,1),
  (5,4),
  (3,5),
  (4,5),
  (5,5);

INSERT INTO
  replies (question_id, parent_id, user_id, body)
VALUES
  (1, NULL, 1, 'The answer is potato || No Parent'),
  (1,1,2,'I found out'),
  (1,2,3,'No the answer is 42 dumbass'),
  (1,2,4,'Can''t count that high'),
  (2,NULL, 1, 'Something||No parent');

-- first col: users second_col: questions
INSERT INTO
  question_likes (user_id, question_id)
VALUES
  (1,1),
  (3,1),
  (2,2),
  (4,3),
  (5,3),
  (5,4);
