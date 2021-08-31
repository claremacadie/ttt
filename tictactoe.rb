# tictactoe.rb
module Formattable
  def clear
    system('clear')
  end

  def blank_line
    puts
  end

  def joinor(arr, delimiter=', ', word='or')
    case arr.size
    when 0 then ''
    when 1 then arr.first
    when 2 then arr.join(" #{word} ")
    else
      arr[-1] = "#{word} #{arr.last}"
      arr.join(delimiter)
    end
  end
end

module Questionable
  include Formattable

  YES_NO_OPTIONS = %w(y yes n no)

  def ask_yes_no_question(question)
    answer = nil
    loop do
      puts question
      answer = gets.chomp.downcase.strip
      break if YES_NO_OPTIONS.include? answer
      puts "Sorry, must be y or n."
      blank_line
    end
    answer[0] == 'y'
  end

  def ask_open_question(question, void_answer)
    answer = nil
    loop do
      puts question
      answer = gets.chomp.strip
      break unless answer.empty? || answer == void_answer
      puts "Sorry, must enter a value (it can't be '#{void_answer}'!)."
      blank_line
    end
    answer
  end

  def ask_closed_question(question, options)
    downcase_options = options.map(&:downcase)
    answer = nil
    loop do
      puts question
      answer = gets.chomp.downcase.strip
      break if downcase_options.include?(answer)
      puts "Sorry, invalid choice."
      blank_line
    end
    answer
  end

  def ask_numeric_choice(question, options)
    answer = nil
    loop do
      puts question
      answer = gets.chomp.strip.to_i
      break if options.include?(answer)
      puts "Sorry, that's not a valid choice."
      blank_line
    end
    answer
  end
end

class Board
  WINNING_LINES = [[1, 2, 3], [4, 5, 6], [7, 8, 9]] +
                  [[2, 5, 8], [1, 4, 7], [3, 6, 9]] +
                  [[1, 5, 9], [3, 5, 7]]
  CENTER_SQUARE = 5

  attr_accessor :human_marker, :computer_marker

  def initialize
    @squares = {}
    reset
  end

  def []=(num, marker)
    @squares[num].marker = marker
  end

  def [](num)
    @squares[num]
  end

  def reset
    (1..9).each { |key| @squares[key] = Square.new }
  end

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/MethodLength
  def draw
    puts "     |     |"
    puts "  #{@squares[1]}  |  #{@squares[2]}  |  #{@squares[3]}"
    puts "     |     |"
    puts "-----+-----+-----"
    puts "     |     |"
    puts "  #{@squares[4]}  |  #{@squares[5]}  |  #{@squares[6]}"
    puts "     |     |"
    puts "-----+-----+-----"
    puts "     |     |"
    puts "  #{@squares[7]}  |  #{@squares[8]}  |  #{@squares[9]}"
    puts "     |     |"
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength

  def unmarked_keys
    @squares.select { |_, sq| sq.unmarked? }.keys
  end

  def full?
    unmarked_keys.empty?
  end

  def someone_won?
    !!winning_marker
  end

  def winning_marker
    WINNING_LINES.each do |line|
      squares = @squares.values_at(*line)
      if three_identical_markers?(squares)
        return squares.first.marker
      end
    end
    nil
  end

  def find_best_square
    if computer_offense_move
      computer_offense_move
    elsif computer_defense_move
      computer_defense_move
    elsif self[CENTER_SQUARE].unmarked?
      self[CENTER_SQUARE]
    else
      self[unmarked_keys.sample]
    end
  end

  private

  def three_identical_markers?(squares)
    markers = squares.select(&:marked?).map(&:marker)
    return false if markers.size != 3
    markers.uniq.size == 1
  end

  def computer_offense_move
    computer_strategic_move(computer_marker)
  end

  def computer_defense_move
    computer_strategic_move(human_marker)
  end

  def computer_strategic_move(marker)
    WINNING_LINES.each do |line|
      squares = @squares.values_at(*line)
      square = find_at_risk_square(squares, marker)
      return square if square
    end
    nil
  end

  def find_at_risk_square(squares, marker_type)
    markers = squares.select(&:marked?).map(&:marker)
    if markers.count(marker_type) == 2 && empty_square(squares)
      return empty_square(squares)
    end
    nil
  end

  def empty_square(squares)
    squares.select(&:unmarked?).first
  end
end

class Square
  INITIAL_MARKER = " "

  attr_accessor :marker

  def initialize(marker = INITIAL_MARKER)
    @marker = marker
  end

  def to_s
    @marker
  end

  def unmarked?
    marker == INITIAL_MARKER
  end

  def marked?
    marker != INITIAL_MARKER
  end
end

class Player
  include Questionable

  COMPUTER_NAME = "Joshua"

  attr_reader :name
  attr_accessor :score, :marker

  def initialize
    @score = 0
  end

  def increment_score
    self.score += 1
  end

  def point_string
    score == 1 ? "point" : "points"
  end
end

class Human < Player
  def initialize
    @name = ask_open_question("What's your name?", COMPUTER_NAME)
    super
  end
end

class Computer < Player
  def initialize
    @name = COMPUTER_NAME
    super
  end
end

class TTTGame
  include Formattable
  include Questionable

  FIRST_TO_MOVE = 'X'
  WINS_LIMIT = 5

  attr_reader :board, :human, :computer

  def initialize
    clear
    @board = Board.new
    @human = Human.new
    @computer = Computer.new
    @current_marker = FIRST_TO_MOVE
  end

  def play
    clear
    display_welcome_message
    loop do
      main_game
      display_champion if match_winner
      break unless play_again?
      reset_match
      display_rematch_message
    end
    display_goodbye_message
  end

  private

  def display_welcome_message
    clear
    puts <<~WELCOME
    Hi #{human.name}. Welcome to Tic Tac Toe!
    You are playing against #{computer.name}.
    The first to win 5 games is the Champion!
    WELCOME
    blank_line
  end

  def main_game
    loop do
      decide_player_markers
      display_board
      player_move
      update_score
      display_result_and_scores
      break if match_winner
      reset_board
      break unless continue_match_message
    end
  end

  def decide_player_markers
    human_marker_choice = ask_closed_question(
      "#{FIRST_TO_MOVE} goes first. Would you like to be 'X' or 'O'?",
      ['x', 'o']
    )
    assign_player_markers(human_marker_choice)
  end

  def assign_player_markers(human_marker_choice)
    if human_marker_choice.upcase == 'O'
      human.marker = 'O'
      computer.marker = 'X'
    else
      human.marker = 'X'
      computer.marker = 'O'
    end
    board.human_marker = human.marker
    board.computer_marker = computer.marker
  end

  def display_board
    clear
    puts "#{human.name} is an #{human.marker}. " \
        "#{computer.name} is an #{computer.marker}."
    blank_line
    board.draw
    blank_line
  end

  def display_result_and_scores
    display_result
    display_scores
  end

  def display_result
    clear_screen_and_display_board

    case board.winning_marker
    when human.marker
      puts "#{human.name} won!"
    when computer.marker
      puts "#{computer.name} won!"
    else
      puts "It's a tie!"
    end
  end

  def display_scores
    puts <<~SCORES
    Remember, the first to win 5 games is the Champion!
    #{human.name} has #{human.score} #{human.point_string}.
    #{computer.name} has #{computer.score} #{computer.point_string}.
    SCORES
  end

  def player_move
    loop do
      current_player_moves
      break if board.someone_won? || board.full?
      clear_screen_and_display_board if human_turn?
    end
  end

  def current_player_moves
    if human_turn?
      human_moves
      @current_marker = computer.marker
    else
      computer_moves
      @current_marker = human.marker
    end
  end

  def human_turn?
    @current_marker == human.marker
  end

  def human_moves
    square = ask_numeric_choice(
      "Choose a square (#{joinor(board.unmarked_keys)}):",
      board.unmarked_keys
    )
    board[square] = human.marker
  end

  def computer_moves
    board.find_best_square.marker = computer.marker
  end

  def clear_screen_and_display_board
    clear
    display_board
  end

  def update_score
    case board.winning_marker
    when human.marker
      human.increment_score
    when computer.marker
      computer.increment_score
    end
  end

  def match_winner
    if human.score == WINS_LIMIT
      human
    elsif computer.score == WINS_LIMIT
      computer
    end
  end

  def display_champion
    blank_line
    puts "#{match_winner.name} won 5 games and is the CHAMPION!"
    blank_line
  end

  def play_again?
    ask_yes_no_question("Would you like to play another match? (y/n)")
  end

  def reset_board
    board.reset
    @current_marker = FIRST_TO_MOVE
  end

  def continue_match_message
    blank_line
    answer = ask_closed_question(
      "Press enter to continue the match (or 'q' to quit this match).",
      ["", "q"]
    )
    clear
    answer.empty? ? true : false
  end

  def display_rematch_message
    clear
    puts <<~REMATCH
    Hi #{human.name}. Welcome back to Tic Tac Toe!
    You are playing against #{computer.name}.
    Remember, the first to win 5 games is the Champion!
    REMATCH
    blank_line
  end

  def reset_match
    reset_board
    human.score = 0
    computer.score = 0
  end

  def display_goodbye_message
    puts "Thank you for playing Tic Tac Toe! Goodbye!"
    blank_line
  end
end

game = TTTGame.new
game.play
