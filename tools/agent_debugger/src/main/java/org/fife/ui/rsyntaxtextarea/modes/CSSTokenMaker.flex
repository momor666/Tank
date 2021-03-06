/*
 * 09/03/2005
 *
 * CSSTokenMaker.java - Token maker for CSS files.
 * Copyright (C) 2005 Robert Futrell
 * robert_futrell at users.sourceforge.net
 * http://fifesoft.com/rsyntaxtextarea
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA.
 */
package org.fife.ui.rsyntaxtextarea.modes;

import java.io.*;
import javax.swing.text.Segment;

import org.fife.ui.rsyntaxtextarea.*;


/**
 * This class splits up text into tokens representing a CSS file.<p>
 *
 * This implementation was created using
 * <a href="http://www.jflex.de/">JFlex</a> 1.4.1; however, the generated file
 * was modified for performance.  Memory allocation needs to be almost
 * completely removed to be competitive with the handwritten lexers (subclasses
 * of <code>AbstractTokenMaker</code>, so this class has been modified so that
 * Strings are never allocated (via yytext()), and the scanner never has to
 * worry about refilling its buffer (needlessly copying chars around).
 * We can achieve this because RText always scans exactly 1 line of tokens at a
 * time, and hands the scanner this line as an array of characters (a Segment
 * really).  Since tokens contain pointers to char arrays instead of Strings
 * holding their contents, there is no need for allocating new memory for
 * Strings.<p>
 *
 * The actual algorithm generated for scanning has, of course, not been
 * modified.<p>
 *
 * If you wish to regenerate this file yourself, keep in mind the following:
 * <ul>
 *   <li>The generated CSSTokenMaker.java</code> file will contain 2
 *       definitions of both <code>zzRefill</code> and <code>yyreset</code>.
 *       You should hand-delete the second of each definition (the ones
 *       generated by the lexer), as these generated methods modify the input
 *       buffer, which we'll never have to do.</li>
 *   <li>You should also change the declaration/definition of zzBuffer to NOT
 *       be initialized.  This is a needless memory allocation for us since we
 *       will be pointing the array somewhere else anyway.</li>
 *   <li>You should NOT call <code>yylex()</code> on the generated scanner
 *       directly; rather, you should use <code>getTokenList</code> as you would
 *       with any other <code>TokenMaker</code> instance.</li>
 * </ul>
 *
 * @author Robert Futrell
 * @version 0.4
 *
 */
%%

%public
%class CSSTokenMaker
%extends AbstractJFlexTokenMaker
%implements TokenMaker
%unicode
%type org.fife.ui.rsyntaxtextarea.Token


%{


/*****************************************************************************/


	/**
	 * Constructor.  This must be here because JFlex does not generate a
	 * no-parameter constructor.
	 */
	public CSSTokenMaker() {
		super();
	}


/*****************************************************************************/


	/**
	 * Adds the token specified to the current linked list of tokens.
	 *
	 * @param tokenType The token's type.
	 */
	private void addToken(int tokenType) {
		addToken(zzStartRead, zzMarkedPos-1, tokenType);
	}


/*****************************************************************************/


	/**
	 * Adds the token specified to the current linked list of tokens.
	 *
	 * @param tokenType The token's type.
	 */
	private void addToken(int start, int end, int tokenType) {
		int so = start + offsetShift;
		addToken(zzBuffer, start,end, tokenType, so);
	}


/*****************************************************************************/


	/**
	 * Adds the token specified to the current linked list of tokens.
	 *
	 * @param array The character array.
	 * @param start The starting offset in the array.
	 * @param end The ending offset in the array.
	 * @param tokenType The token's type.
	 * @param startOffset The offset in the document at which this token
	 *                    occurs.
	 */
	public void addToken(char[] array, int start, int end, int tokenType, int startOffset) {
		super.addToken(array, start,end, tokenType, startOffset);
		zzStartRead = zzMarkedPos;
	}


/*****************************************************************************/


	/**
	 * Returns the first token in the linked list of tokens generated
	 * from <code>text</code>.  This method must be implemented by
	 * subclasses so they can correctly implement syntax highlighting.
	 *
	 * @param text The text from which to get tokens.
	 * @param initialTokenType The token type we should start with.
	 * @param startOffset The offset into the document at which
	 *        <code>text</code> starts.
	 * @return The first <code>Token</code> in a linked list representing
	 *         the syntax highlighted text.
	 */
	public Token getTokenList(Segment text, int initialTokenType, int startOffset) {

		resetTokenList();
		this.offsetShift = -text.offset + startOffset;

		// Start off in the proper state.
		int state = Token.NULL;
		switch (initialTokenType) {
			case Token.LITERAL_STRING_DOUBLE_QUOTE:
				state = STRING;
				start = text.offset;
				break;
			case Token.LITERAL_CHAR:
				state = CHAR_LITERAL;
				start = text.offset;
				break;
			case Token.COMMENT_MULTILINE:
				state = C_STYLE_COMMENT;
				start = text.offset;
				break;
			case Token.COMMENT_DOCUMENTATION:
				state = CD_COMMENT;
				start = text.offset;
				break;
			default:
				state = Token.NULL;
		}

		s = text;
		try {
			yyreset(zzReader);
			yybegin(state);
			return yylex();
		} catch (IOException ioe) {
			ioe.printStackTrace();
			return new DefaultToken();
		}

	}


/*****************************************************************************/


	/**
	 * Refills the input buffer.
	 *
	 * @return      <code>true</code> if EOF was reached, otherwise
	 *              <code>false</code>.
	 * @exception   IOException  if any I/O-Error occurs.
	 */
	private boolean zzRefill() throws java.io.IOException {
		return zzCurrentPos>=s.offset+s.count;
	}


/*****************************************************************************/


	/**
	 * Resets the scanner to read from a new input stream.
	 * Does not close the old reader.
	 *
	 * All internal variables are reset, the old input stream 
	 * <b>cannot</b> be reused (internal buffer is discarded and lost).
	 * Lexical state is set to <tt>YY_INITIAL</tt>.
	 *
	 * @param reader   the new input stream 
	 */
	public final void yyreset(java.io.Reader reader) throws java.io.IOException {
		// 's' has been updated.
		zzBuffer = s.array;
		/*
		 * We replaced the line below with the two below it because zzRefill
		 * no longer "refills" the buffer (since the way we do it, it's always
		 * "full" the first time through, since it points to the segment's
		 * array).  So, we assign zzEndRead here.
		 */
		//zzStartRead = zzEndRead = s.offset;
		zzStartRead = s.offset;
		zzEndRead = zzStartRead + s.count - 1;
		zzCurrentPos = zzMarkedPos = zzPushbackPos = s.offset;
		zzLexicalState = YYINITIAL;
		zzReader = reader;
		zzAtBOL  = true;
		zzAtEOF  = false;
	}


/*****************************************************************************/

%}

ident				= ([-]?{nmstart}{nmchar}*)
name					= ({nmchar}+)
nmstart				= ([_a-zA-Z]|{nonascii}|{escape})
nonascii				= ([^\0-\177])
unicode				= (\\[0-9a-f]{1,6}[ \n\t\f]?)
escape				= ({unicode}|\\[^\n\r\f0-9a-f])
nmchar				= ([_a-zA-Z0-9\-]|{nonascii}|{escape})
num					= ([0-9]+|[0-9]*\.[0-9]+)
w					= ([ \t\n\f])

IDENT				= ({ident})
ATKEYWORD				= (@{ident})
HASH					= (#{name})
NUMBER				= ({num})
PERCENTAGE			= ({num}%)
DIMENSION				= ({num}{ident})
UNICODE_RANGE			= (U\+[0-9A-F?]{1,6}(-[0-9A-F]{1,6})?)
CDO					= ("<!--")
CDC					= ("-->")
SEPARATOR				= ([;\{\}\(\)\[\]])
S					= ({w}+)
COMMENT_START			= ("/*")
COMMENT_END			= ("*/")
FUNCTION				= ({ident}\()
INCLUDES				= (\~=)
DASHMATCH				= (\|=)


%state STRING
%state CHAR_LITERAL
%state CD_COMMENT
%state C_STYLE_COMMENT


%%

<YYINITIAL> {

	{IDENT}			{ addToken(Token.IDENTIFIER); }
	{ATKEYWORD}		{ addToken(Token.VARIABLE); }
	\"				{ start = zzMarkedPos-1; yybegin(STRING); }
	\'				{ start = zzMarkedPos-1; yybegin(CHAR_LITERAL); }
	{HASH}			{ addToken(Token.VARIABLE); }
	{NUMBER}			{ addToken(Token.LITERAL_NUMBER_DECIMAL_INT); }
	{PERCENTAGE}		{ addToken(Token.DATA_TYPE); }
	{DIMENSION}		{ addToken(Token.DATA_TYPE); }
	{UNICODE_RANGE}	{ addToken(Token.FUNCTION); }
	{CDO}			{ start = zzMarkedPos-4; yybegin(CD_COMMENT); }
	{SEPARATOR}		{ addToken(Token.SEPARATOR); }
	{S}				{ addToken(Token.WHITESPACE); }
	{COMMENT_START}	{ start = zzMarkedPos-2; yybegin(C_STYLE_COMMENT); }
	{FUNCTION}		{ addToken(Token.FUNCTION); }
	{INCLUDES}		{ addToken(Token.OPERATOR); }
	{DASHMATCH}		{ addToken(Token.OPERATOR); }
	.				{ addToken(Token.IDENTIFIER); }
	<<EOF>>			{ addNullToken(); return firstToken; }

}

<STRING> {
	[^\n\"]+			{}
	\n				{ addToken(start,zzStartRead-1, Token.ERROR_STRING_DOUBLE); addNullToken(); return firstToken; }
	\"				{ addToken(start,zzStartRead, Token.LITERAL_STRING_DOUBLE_QUOTE); yybegin(YYINITIAL); }
	<<EOF>>			{ addToken(start,zzStartRead-1, Token.ERROR_STRING_DOUBLE); return firstToken; }
}

<CHAR_LITERAL> {
	[^\n\']+			{}
	\n				{ addToken(start,zzStartRead-1, Token.ERROR_CHAR); addNullToken(); return firstToken; }
	\'				{ addToken(start,zzStartRead, Token.LITERAL_CHAR); yybegin(YYINITIAL); }
	<<EOF>>			{ addToken(start,zzStartRead-1, Token.ERROR_CHAR); return firstToken; }
}

<CD_COMMENT> {
	[^\n\-]+			{}
	\n				{ addToken(start,zzStartRead-1, Token.COMMENT_DOCUMENTATION); return firstToken; }
	{CDC}			{ yybegin(YYINITIAL); addToken(start,zzStartRead+2, Token.COMMENT_DOCUMENTATION); }
	\-				{}
	<<EOF>>			{ addToken(start,zzStartRead-1, Token.COMMENT_DOCUMENTATION); return firstToken; }
}

<C_STYLE_COMMENT> {

	[^\n\*]+			{}
	\n				{ addToken(start,zzStartRead-1, Token.COMMENT_MULTILINE); return firstToken; }
	{COMMENT_END}		{ yybegin(YYINITIAL); addToken(start,zzStartRead+1, Token.COMMENT_MULTILINE); }
	\*				{}
	<<EOF>>			{ addToken(start,zzStartRead-1, Token.COMMENT_MULTILINE); return firstToken; }

}
