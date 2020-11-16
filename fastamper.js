// ==UserScript==
// @name         Fastmail Shortcuts
// @namespace    http://tampermonkey.net/
// @version      0.2
// @description  mouse less, keyboard more
// @author       rjbs
// @match        https://*.fastmail.com/mail/*
// @grant        none
// ==/UserScript==

(function() {
  'use strict';
  const observer = new MutationObserver(() => {
    if (document.getElementById('bootstrap-page')) {
      return;
    }
    observer.disconnect();

    const css = FM.el(
      'style',
      { type: 'text/css' },
      [ '.rjbs-MSV-Hidden-3 .v-MailboxSource-badge { background-color: #e3d8f0 }' ],
    );
    document.body.appendChild(css);

    const shortcut = (keystroke, fn) => {
      FM.ViewEventsController.kbShortcuts.register(keystroke, { do: fn }, 'do');
    };

    shortcut(
      'Cmd-Shift-L',
      () => {
        if (FM.userPrefs.get('theme') === 'steel') {
          FM.userPrefs.set('theme', 'dark');
        } else {
          FM.userPrefs.set('theme', 'steel');
        }
      },
    );

    const mail = FM.router.getAppController('mail');
    shortcut('Cmd-Shift-9', () => mail.sources.get('sourceGroups')[0].content.forEach(s => s.set('isCollapsed', true)));
    shortcut('Cmd-Shift-0', () => mail.sources.get('sourceGroups')[0].content.forEach(s => s.set('isCollapsed', false)));

    shortcut('(', () => mail.set('mailboxFilter', ''));
    shortcut('|', () => mail.set('mailboxFilter', 'inbox'));
    shortcut(')', () => mail.set('mailboxFilter', 'unread'));

    shortcut('Cmd-Shift-Z', () => FM.preferences.toggle('enableConversations'));
    shortcut('Cmd-Shift-D', () => FM.preferences.toggle('showSidebar'));
    shortcut('Cmd-Shift-G', () => mail.toggle('searchIsGlobal'));
    shortcut('Cmd-Shift-P', () => FM.preferences.toggle('showReadingPane'));

    const clippy = {
      text: {
        cycle: 0,
        range: null,
        opts : [ '#a00', '#a0a', '#3b874b', '#d68b00', '#43219c', null ],
      },
      block: {
        cycle: 0,
        range: null,
        opts : [
          (e) => { e.style.backgroundColor = '#dacae0'; e.style.color = '#54365e'; },
          (e) => { e.style.backgroundColor = '#f5fca7'; e.style.color = '#9c6500'; },
          (e) => { e.style.backgroundColor = '#c3e0c9'; e.style.color = '#275731'; },
          (e) => { e.style.backgroundColor = null; e.style.color = null; },
        ],
      },
      nextFor: function (key, range) {
        const state = this[key];
        state.cycle = (state.range && (range.compareBoundaryPoints(Range.END_TO_END, state.range) == 0))
        ? ((state.cycle + 1) % state.opts.length)
        : 0;

        return state.opts[ state.cycle ];
      },
    };

    const getViewsByClass = (viewClass) => {
      return Object.values(FM.activeViews).filter(view => view instanceof viewClass);
    }

    const krazyKolour = () => {
      let editorViews = getViewsByClass(FM.classes.RichTextView);
      if (editorViews.length != 1) {
        console("RJBS:  Wanted exactly one v-RichText but got " + editorViews.length + ".");
        return null;
      }

      let editor = editorViews[0].editor;

      if (! editor) {
        console.log("No editor?  I give up.");
        return null;
      }

      const range = editor.getSelection();
      if (range.collapsed) {
        const quote = (range.startContainer instanceof Element)
        ? range.startContainer.closest('blockquote')
        : range.startContainer.parentElement.closest('blockquote');

        if (! quote) {
          console.log("Not inside a blockquote.");
          return null;
        }

        const munger = clippy.nextFor('block', range);
        munger(quote);
        clippy.block.range = editor.getSelection();
      } else {
        const color = clippy.nextFor('text', range);

        editor.setTextColour( color );
        clippy.text.range = editor.getSelection();
      }
    };

    shortcut('Cmd-Shift-K', krazyKolour);

    FM.classes.Mailbox.prototype.badgeProperty = function () {
      var role = this.get('role');

      if ( role === 'drafts' ) return 'totalEmails';
      if ( role === 'archive' || role === 'sent' || role === 'trash' || role === 'snoozed' ) {
        return null;
      }

      var forceEmail = this.get('isShared') && !this.get('isSeenShared');

      // No easy reference to HIDE_IF_EMPTY so use hardcoded value
      if ( this.get('hidden') === 3) {
        return forceEmail ? 'totalEmails' : 'total';
      }

      return forceEmail ? 'unreadEmails' : 'unread';
    }.property( 'role', 'isShared', 'isSeenShared', 'hidden' );

    FM.store.getAll(FM.classes.Mailbox).forEach(mailbox => mailbox.computedPropertyDidChange('badgeProperty'));

    FM.classes.MailboxSourceView.prototype.className = function () {
      var role = this.get( 'content' ).get( 'role' );
      var isCollapsed = !this.get( 'hasSubfolders' ) || this.get( 'isCollapsed' );

      return 'v-MailboxSource' +
      ( role ? ' v-MailboxSource--' + role : '' ) +
      ( ' rjbs-MSV-Hidden-' + this.get('content').get('hidden') ) +
      ( isCollapsed ? '' : ' is-expanded' ) +
      ( isCollapsed && this.get( 'hasUnreadChildren' ) ? ' u-bold' : '' );
    }.property( 'hasSubfolders', 'isCollapsed', 'hasUnreadChildren' );

    getViewsByClass(FM.classes.MailboxSourceView).forEach(
      view => view.computedPropertyDidChange('className')
    );
  });
  observer.observe(document.body, { childList: true });
})();
