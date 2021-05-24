// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.

import Rails from '@rails/ujs';
import Turbolinks from 'turbolinks';
import '../reservation';
// import '../admin_reservation';
import { menuSortable } from '../menu_sortable';

Rails.start();
Turbolinks.start();

document.addEventListener('turbolinks:load', () => {
  if (location.pathname == '/admin/menus') {
    menuSortable();
  }
});
