~~~~~~~~~~~~~~~~~~~~~~~~~~~
readme file for logger pipe
~~~~~~~~~~~~~~~~~~~~~~~~~~~

The purpose of logger pipe is to provide "normal" logging behaviour in 
environments where the normal logger implementations cannot be used.

  In a nut shell, logger pipe is a long winded way of achieving autonomous 
  transactions without using the autonomous_transaction pragma.

Normal logging behaviour is saving logger data in Oracle tables via autonomous
transactions. i.e. The logger data is saved no matter what happens to the
transaction from which the logger call was made.

In Oracle 8i, autonomous transactions cannot be started from within a 
distributed transaction. 
If an application running on 8i will use distributed transactions 
(i.e. database links) it should use the logger pipe implementation.


It is strongly recommended that if you can use the normal logger 
implementation, you do.

  In some situations, logger pipe will run faster than the normal logger 
  implementation but this is not a good reason to use it.
