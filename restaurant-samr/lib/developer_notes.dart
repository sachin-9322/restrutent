/*
Git:
main -> production release
stage -> sarfaraz will test here
debug -> internal tester

developer -> latest merge stable code; always push stable code in developer branch
feature/room-type => developer hasnain
feature/tcp-udp-communication => developer ifra
feature/table => developer muzakkir
bugfix/responsive-ui
improvement/dark-light-mode
_____
flutter pub run build_runner build
dart run build_runner build --delete-conflicting-outputs



improvement/table-update =>1. Enable Editing fot the tables in Fragment_table
   (Hasnain)               2. Add Delete IconButton in Fragment_table
                           3. Arange the sequence of menuList in RepoHome eg:(1st priority category and 2nd one Food)
                           4. In the EntityCategory Give byDefault value for Column(isActive = true)


imrpovment/food-update => 1. Adding Delete IconButton in Fragment_Food,FragmentRoom , FragmentCategory
  (Hasnain)               2. bug:(after editing food details after editing category we cant access the previous
                             category food items but these all previous category food items are showing in the fragment_food))
                          3. improvement in the food card
                          4. just change FloatingActionButton style in FragmentTable
                          5. In the FragmentCategory improvement after searching Category show searched category list by its name
*
* */

// to do 

// short code $shortcode space 5 and do wiht split then that food will add wiht 5 
///  setup.exe befroe downlaod all lib and assign locally sd k zip 