# tictactoe.rb
module Formattable
  def break_line
    puts "------------------------------------------------------------------"
  end

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
  YES_NO_OPTIONS = %w(y yes n no)

  def ask_yes_no_question(question)
    answer = nil
    loop do
      puts question
      answer = gets.chomp.downcase.strip
      break if YES_NO_OPTIONS.include? answer
      puts "Sorry, must be y or n."
    end
    answer[0] == 'y'
  end

  def ask_open_question(question, char_limit = 0)
    answer = nil
    loop do
      puts question
      answer = gets.chomp.strip
      break unless answer.empty? || answer.size > char_limit
      puts "Sorry, must enter a value and it must be less than 15 characters."
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
    end
    answer
  end

  def ask_numeric_choice(question, options)
    answer = nil
    loop do
      puts question
      answer = gets.chomp.to_i
      break if options.include?(answer)
      puts "Sorry, that's not a valid choice."
    end
    answer
  end
end

class Board
  WINNING_LINES = [[1, 2, 3], [4, 5, 6], [7, 8, 9]] +
                  [[2, 5, 8], [1, 4, 7], [3, 6, 9]] +
                  [[1, 5, 9], [3, 5, 7]]

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

  private

  def three_identical_markers?(squares)
    markers = squares.select(&:marked?).collect(&:marker)
    return false if markers.size != 3
    markers.uniq.size == 1
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

  attr_reader :marker, :name
  attr_accessor :score

  def initialize(marker)
    @marker = marker
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
  def initialize(marker)
    @name = ask_open_question("What's your name?", 15)
    super
  end
end

class Computer < Player
  def initialize(marker)
    @name = "Joshua"
    super
  end
end

class TTTGame
  include Formattable
  include Questionable

  HUMAN_MARKER = 'X'
  COMPUTER_MARKER = 'O'
  FIRST_TO_MOVE = HUMAN_MARKER
  CENTER_SQUARE = 5
  WINS_LIMIT = 5

  attr_reader :board, :human, :computer

  def initialize
    clear
    @board = Board.new
    @human = Human.new(HUMAN_MARKER)
    @computer = Computer.new(COMPUTER_MARKER)
    @current_marker = FIRST_TO_MOVE
  end

  def play
    clear
    display_welcome_message
    main_game
    display_champion
    display_goodbye_message
  end

  private

  def display_welcome_message
    clear
    puts "Hi #{human.name}. Welcome to Tic Tac Toe!"
    puts "You are playing against #{computer.name}."
    puts "The first to win 5 games is the Champion!"
    blank_line
  end

  def main_game
    loop do
      display_board
      player_move
      update_score
      display_result
      display_scores
      break if match_winner
      reset
      display_play_again_message
    end
  end

  def display_board
    puts "#{human.name} is an #{human.marker}. " \
        "#{computer.name} is an #{computer.marker}."
    blank_line
    board.draw
    blank_line
  end

  def display_scores
    puts "#{human.name} has #{human.score} #{human.point_string}."
    puts "#{computer.name} has #{computer.score} #{computer.point_string}."
    puts "Remember, the first to win 5 games is the Champion!"
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
      @current_marker = COMPUTER_MARKER
    else
      computer_moves
      @current_marker = HUMAN_MARKER
    end
  end

  def human_turn?
    @current_marker == HUMAN_MARKER
  end

  def human_moves
    square = ask_numeric_choice(
      "Choose a square (#{joinor(board.unmarked_keys)}):",
      board.unmarked_keys
    )
    board[square] = human.marker
  end

  def computer_moves
    if board[CENTER_SQUARE].marker == Square::INITIAL_MARKER
      board[CENTER_SQUARE] = computer.marker
    else
      board[board.unmarked_keys.sample] = computer.marker
    end
  end

  def clear_screen_and_display_board
    clear
    display_board
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

  def update_score
    case board.winning_marker
    when human.marker
      human.increment_score
    when computer.marker
      computer.increment_score
    end
  end

  def match_winner
    if human.score == 5
      human
    elsif computer.score == 5
      computer
    end
    nil
  end

  def display_champion
    puts "#{match_winner} won 5 games and is the CHAMPION!"
  end

  def play_again?
    ask_yes_no_question("Would you like to play another match? (y/n)")
  end

  def reset
    board.reset
    @current_marker = FIRST_TO_MOVE
    # clear
  end

  def display_play_again_message
    puts
    puts "Press enter to continue the match."
    gets
    clear
  end

  def display_goodbye_message
    puts "Thanks for playing Tic Tac Toe! Goodbye!"
    puts
  end
end

game = TTTGame.new
game.play
