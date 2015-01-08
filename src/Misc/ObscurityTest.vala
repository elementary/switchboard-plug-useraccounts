/***
Copyright (C) 2015 Marvin Beckers
This program is free software: you can redistribute it and/or modify it
under the terms of the GNU General Public License version 3, as published
by the Free Software Foundation.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranties of
MERCHANTABILITY, SATISFACTORY QUALITY, or FITNESS FOR A PARTICULAR
PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along
with this program. If not, see http://www.gnu.org/licenses/.

This class is based on obscure.c from passwd. License for obscure.c's source code:

 * Copyright (c) 1989 - 1994, Julianne Frances Haugh
 * Copyright (c) 1996 - 1999, Marek Michałkiewicz
 * Copyright (c) 2003 - 2005, Tomasz Kłoczko
 * Copyright (c) 2007 - 2010, Nicolas François
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. The name of the copyright holders or contributors may not be used to
 *    endorse or promote products derived from this software without
 *    specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 * PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT
 * HOLDERS OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
***/

namespace SwitchboardPlugUserAccounts {
    public class ObscurityTest {
        public ObscurityTest () { }

        public enum RESULT {
            OBSCURE,
            SHORT,
            PALINDROME,
            SIMILIAR,
            SIMPLE
        }

        public static ObscurityTest.RESULT test (string _oldpw, string _newpw) {
            if (_oldpw.down () == _newpw.down () || is_similiar (_oldpw, _newpw))
                return ObscurityTest.RESULT.SIMILIAR;

            if (is_simple (_newpw))
                return ObscurityTest.RESULT.SIMPLE;

            if (is_palindrome (_newpw))
                return ObscurityTest.RESULT.PALINDROME;

            return ObscurityTest.RESULT.OBSCURE;
        }

        private static bool is_similiar (string _oldpw, string _newpw) {
            char[] oldpw = _oldpw.to_utf8 ();
            char[] newpw = _newpw.to_utf8 ();
            int i;
            int j;

            if (_newpw.length >= 8)
                return false;

            for (i = j = 0; ('\0' != newpw[i]) && ('\0' != oldpw[i]); i++) {
                if (Posix.strchr (_newpw, oldpw[i]) != null)
                    j++;
            }

            if (i >= j * 2)
                return false;
    
            return true;
        }

        private static bool is_simple (string _newpw) {
            char[] newpw = _newpw.to_utf8 ();
            bool digits = false;
            bool uppers = false;
            bool lowers = false;
            bool others = false;
            int size = 9;
            int i;

            for (i = 0; '\0' != newpw[i]; i++) {
                if (newpw[i].isdigit ())
                    digits = true;
                else if (newpw[i].isupper ())
                    uppers = true;
                else if (newpw[i].islower ())
                    lowers = true;
                else
                    others = true;
            }

            if (digits)
                size--;
            if (uppers)
                size--;
            if (lowers)
                size--;
            if (others)
                size--;

            if (size <= i)
                return false;

            return true;
        }

        private static bool is_palindrome (string _newpw) {
            char[] newpw = _newpw.to_utf8 ();
            size_t i, j;
            i = _newpw.length;

            for (j = 0; j < i; j++) {
                if (newpw[i - j - 1] != newpw[j])
                    return false;
            }
            return true;
        }
    }
}
