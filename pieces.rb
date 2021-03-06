class Piece

  STRAIGHT = [[1, 0], [0, 1], [-1, 0], [0, -1]]
  DIAGONAL = [[1, 1], [-1, 1], [1, -1], [-1, -1]]
  HORSE =    [[-2, 1], [-1, 2], [2, 1], [-2, -1],
              [1, -2], [-1, -2], [2, -1], [1, 2]]

  attr_accessor :pos, :color, :board

  def initialize(pos, color, board)
    @pos = pos
    @color = color
    @board = board
    @has_moved = false
  end

  def pos_add(pos1, pos2)
    [pos1[0] + pos2[0], pos1[1] + pos2[1]]
  end

  def self.pos_add(pos1, pos2)
    [pos1[0] + pos2[0], pos1[1] + pos2[1]]
  end

  def self.on_board?(pos)
    pos.all? { |num| num.between?(0, 7) }
  end

  def valid_moves
    moves.reject { |move| move_into_check?(move) }
  end

  def move_into_check?(square)
    new_board = board.dup
    new_board.move!(pos, square)
    new_board.in_check?(color)
  end

  def has_moved=(value)
    @has_moved = value
  end

  def has_moved?
    @has_moved
  end

  def square_color
    (pos.inject(:+) % 2 == 0)? :dark : :light
  end

end

class SlidingPiece < Piece

  def moves(directions)
    moves = []

    directions.each do |dir|
      current_pos = pos_add(pos, dir)
      while Piece.on_board?(current_pos)
        unless board[current_pos].nil?
          moves << current_pos unless board[current_pos].color == self.color
          break
        end

        moves << current_pos
        current_pos = pos_add(current_pos, dir)
      end
    end

    moves
  end

end

class SteppingPiece < Piece

  def moves(directions)
    moves = []

    directions.each do |dir|
      new_pos = pos_add(pos, dir)
      if Piece.on_board?(new_pos)
        unless !board[new_pos].nil? && board[new_pos].color == self.color
          moves << new_pos
        end
      end
    end

    moves
  end

end

class Pawn < Piece

  attr_reader :prom_line, :direction
  attr_accessor :pass_left, :pass_right

  def initialize(pos, color, board)
    @direction = color == :black ? -1 : 1
    @start_y = color == :black ? 6 : 1
    @prom_line = color == :black ? 0 : 7
    @pass_left, @pass_right = false, false
    super
  end

  def render
    color == :black ? "\u265f" : "\u2659"
  end

  def moves
    moves = diagonal_moves + vertical_moves + en_passant_moves
  end

  def diagonal_moves
    moves = [pos_add(pos, [1, @direction]), pos_add(pos, [-1, @direction])]

    moves.select do |move|
      Piece.on_board?(move) &&
      @board[move] &&
      @board[move].color != self.color
    end
  end

  def vertical_moves
    new_pos = pos_add(pos, [0, @direction])

    return [] unless @board[new_pos].nil? && Piece.on_board?(new_pos)

    moves = [new_pos]

    if pos[1] == @start_y
      new_pos = pos_add(pos, [0, 2 * @direction])
      moves << new_pos if @board[new_pos].nil?
    end

    moves
  end

  def en_passant_moves
    # p "PassLeft: #{pass_left}"
    # p "PassRight: #{pass_right}"
    [].tap do |moves|
      moves << pos_add(pos, [1, @direction]) if pass_right
      moves << pos_add(pos, [-1, @direction]) if pass_left
    end
  end

  def reset_en_passant
    @pass_left, @pass_right = false, false
  end

end

class Queen < SlidingPiece

  def moves
    super(STRAIGHT + DIAGONAL)
  end

  def render
    color == :black ? "\u265b" : "\u2655"
  end

end

class Rook < SlidingPiece

  def moves
    moves = super(STRAIGHT)
    direction = (pos[1] == 0 ? :left : :right)
    if board.can_castle?(direction, color)
      moves << (direction == :left ? [3, pos[1]] : [5, pos[1]])
    end

    moves
  end

  def render
    color == :black ? "\u265c" : "\u2656"
  end

end

class Bishop < SlidingPiece

  def moves
    super(DIAGONAL)
  end

  def render
    color == :black ? "\u265d" : "\u2657"
  end

end

class Knight < SteppingPiece

  def moves
    super(HORSE)
  end

  def render
    color == :black ? "\u265e" : "\u2658"
  end

end

class King < SteppingPiece

  def moves
    moves = super(STRAIGHT + DIAGONAL)
    moves << [2, pos[1]] if board.can_castle?(:left, color)
    moves << [6, pos[1]] if board.can_castle?(:right, color)

    moves
  end

  def render
    color == :black ? "\u265a" : "\u2654"
  end
end
