class BookCopiesController < ApplicationController
  before_action :set_book, only: :create
  before_action :set_book_copy, only: %i[ edit update destroy ]

  def create
    @book_copy = BookCopy.new(book_copy_params.merge(book: @book))

    if @book_copy.save
      redirect_to @book, notice: "La copia è stata aggiunta."
    else
      render "books/show", status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @book_copy.update(book_copy_params)
      redirect_to @book_copy.book, notice: "La copia è stata aggiornata.", status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    if @book_copy.destroy
      redirect_to @book_copy.book, notice: "La copia è stata eliminata.", status: :see_other
    else
      redirect_to @book_copy.book, alert: @book_copy.errors.full_messages.to_sentence, status: :see_other
    end
  end

  private
    def set_book
      @book = Book.find(params.expect(:book_id))
    end

    def set_book_copy
      @book_copy = BookCopy.find(params.expect(:id))
    end

    def book_copy_params
      params.expect(book_copy: [ :inventory_code, :location ])
    end
end
