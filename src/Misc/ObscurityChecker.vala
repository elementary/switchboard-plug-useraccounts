/***
  Copyright (C) 2014-2015 Switchboard User Accounts Plug Developer
  This program is free software: you can redistribute it and/or modify it
  under the terms of the GNU Lesser General Public License version 3, as published
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
    public class ObscurityChecker {
        public ObscurityChecker () { }

        public enum Result {
            OBSCURE,
            SHORT,
            PALINDROME,
            SIMILIAR,
            SIMPLE
        }

        public static Result test (string old_password, string new_password) {
            if (old_password.down () == new_password.down () || is_similiar (old_password, new_password))
                return Result.SIMILIAR;

            if (is_simple (new_password))
                return Result.SIMPLE;

            if (is_palindrome (new_password))
                return Result.PALINDROME;

            return Result.OBSCURE;
        }

        private static bool is_similiar (string old_password, string new_password) {
            char[] old_password_ar = old_password.to_utf8 ();
            char[] new_password_ar = new_password.to_utf8 ();
            int i;
            int j;

            if (new_password.length >= 8)
                return false;

            for (i = j = 0; ('\0' != new_password_ar[i]) && ('\0' != old_password_ar[i]); i++) {
                if (Posix.strchr (new_password, old_password_ar[i]) != null)
                    j++;
            }

            if (i >= j * 2)
                return false;
    
            return true;
        }

        private static bool is_simple (string new_password) {
            char[] new_password_ar = new_password.to_utf8 ();
            bool digits = false;
            bool uppers = false;
            bool lowers = false;
            bool others = false;
            int size = 9;
            int i;

            for (i = 0; '\0' != new_password_ar[i]; i++) {
                if (new_password_ar[i].isdigit ())
                    digits = true;
                else if (new_password_ar[i].isupper ())
                    uppers = true;
                else if (new_password_ar[i].islower ())
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

        private static bool is_palindrome (string new_password) {
            char[] new_password_ar = new_password.to_utf8 ();
            size_t i, j;
            i = new_password.length;

            for (j = 0; j < i; j++) {
                if (new_password_ar[i - j - 1] != new_password_ar[j])
                    return false;
            }
            return true;
        }
    }
}
