The testbench to use is called "tb_big_mac_gemm"
To run the testbench, the following two commands should be ran from the top directory ("cpaep_2526_stubbe_vandenbroeck"):

    source ./questa_setup.sh
    make TEST_MODULE=tb_big_mac_gemm questasim-run

The result of the test will be printed in terminal. 
For each workload case:
    "Result matrix C verification passed!" will be shown if the test was succesful
    "Result matrix C verification failed!" will be shown if the test failed

To test for workloads differing of the three specified by the project assignment, or for testing different MAC configurations,
the parameters in line 25-34 should be changed to match the preferred parameters.