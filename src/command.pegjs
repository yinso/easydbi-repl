/*
 * extended sexp parser.
 * This one works with javascript objects...
 */
{
  var loglet = require('loglet');
  
  function makeNumberAST(num, frac, exp) {
    return parseFloat([num, frac, exp].join(''));
  }
  
  function makeObjectAST(keyVals) {
    var object = {}
    for (var i = 0; i < keyVals.length; ++i) {
      kv = keyVals[i];
      object[kv[0]] = kv[1];
    }
    return object;
  }
  
  function makeSymbolAST(c1, rest) {
    symbol = [ c1 ].concat(rest).join('')
    switch (symbol) {
    case 'true':
      return true;
    case 'false':
      return false;
    case 'null': 
      return null;
    default:
      return symbol;
    }
  }
  
  function makeStringAST(chars) {
    if (chars instanceof Array) {
      return chars.join('');
    } else {
      return chars;
    }
  }
}
 
start
= _ e:Command _ { return e;}

Command
= e:SetupCmd _ { return e; }
/ e:UseCmd _ { return e; }
/ e:ShowCmd _ { return e; }

SetupCmd
= 'setup' _ name:SymbolExp _ type:StringExp _ options:ObjectExp _ {
  return {command: 'setup', args: [ name, type, options] }; 
}

UseCmd
= 'use' _ name:SymbolExp _ { return { command: 'use', args: [ name ]}; }

ShowCmd
= 'show' _ 'setups' { return {command: 'show', args: [ 'setups' ]}; }

Expression
= ObjectExp
/ BoolExp
/ StringExp
/ NumberExp
/ NullExp

BoolExp
= 'true' _ { return true; }
/ 'false' _ { return false; }

NullExp
= 'null' _ { return null; }

ObjectExp
= '{' keyVals:keyValExp* '}' _ { return makeObjectAST(keyVals); }

keyValExp
= key:keyExp _ ':' _ val:Expression _ keyValDelim? { return [ key, val ]; }

keyValDelim
= ',' _ { return ',' }

keyExp
= s:SymbolExp { return s; }
/ s:StringExp { return s; }


/* === SymbolExp === */
SymbolExp 
= c1:symbol1stChar rest:symbolRestChar* { return makeSymbolAST(c1, rest); }

symbol1stChar
= [^0-9\(\)\;\ \"\'\,\`\{\}\.\,\:\[\]]

symbolRestChar
= [^\(\)\;\ \"\'\,\`\{\}\.\,\:\[\]]

/* === STRING === */

StringExp
= '"' chars:doubleQuoteChar* '"' _ { return makeStringAST(chars); }
/ "'" chars:singleQuoteChar* "'" _ { return makeStringAST(chars); }

singleQuoteChar
  = '"'
  / char

doubleQuoteChar
  = "'"
  / char

char
  // In the original JSON grammar: "any-Unicode-character-except-"-or-\-or-control-character"
  = [^"'\\\0-\x1F\x7f]
  / '\\"'  { return '"';  }
  / "\\'"  { return "'"; }
  / "\\\\" { return "\\"; }
  / "\\/"  { return "/";  }
  / "\\b"  { return "\b"; }
  / "\\f"  { return "\f"; }
  / "\\n"  { return "\n"; }
  / "\\r"  { return "\r"; }
  / "\\t"  { return "\t"; }
  / whitespace 
  / "\\u" digits:hexDigit4 {
      return String.fromCharCode(parseInt("0x" + digits));
    }

/* ==== NUMBERS ==== */

hexDigit4
  = h1:hexDigit h2:hexDigit h3:hexDigit h4:hexDigit { return h1+h2+h3+h4; }

NumberExp
  = int:int frac:frac exp:exp _ { 
    return makeNumberAST(int, frac, exp);
  }
  / int:int frac:frac _     { 
    return makeNumberAST(int, frac, '');
  }
  / '-' frac:frac _ { 
    return makeNumberAST('-', frac, '');
  }
  / frac:frac _ { 
    return makeNumberAST('', frac, '');
  }
  / int:int exp:exp _      { 
    return makeNumberAST(int, '', exp);
  }
  / int:int _          { 
    return makeNumberAST(int, '', '');
  }

int
  = digits:digits { return digits.join(''); }
  / "-" digits:digits { return ['-'].concat(digits).join(''); }

frac
  = "." digits:digits { return ['.'].concat(digits).join(''); }

exp
  = e digits:digits { return ['e'].concat(digits).join(''); }

digits
  = digit+

e
  = [eE] [+-]?

digit
  = [0-9]

digit19
  = [1-9]

hexDigit
  = [0-9a-fA-F]


_ "whitespace"
  = whitespace*

// Whitespace is undefined in the original JSON grammar, so I assume a simple
// conventional definition consistent with ECMA-262, 5th ed.
whitespace
  = comment
  / [ \t\n\r]


lineTermChar
  = [\n\r\u2028\u2029]

lineTerm "end of line"
  = "\r\n"
  / "\n"
  / "\r"
  / "\u2028" // line separator
  / "\u2029" // paragraph separator

sourceChar
  = .

// should also deal with comment.
comment
  = multiLineComment
  / singleLineComment

singleLineCommentStart
  = '//' // c style

singleLineComment
  = singleLineCommentStart chars:(!lineTermChar sourceChar)* lineTerm? { 
    return {comment: chars.join('')}; 
  }

multiLineComment
  = '/*' chars:(!'*/' sourceChar)* '*/' { return {comment: chars.join('')}; }
