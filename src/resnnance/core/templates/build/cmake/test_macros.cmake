macro (add_test_sources)
    file (RELATIVE_PATH _relPath "${CMAKE_SOURCE_DIR}" "${CMAKE_CURRENT_SOURCE_DIR}")
    foreach (_src ${ARGN})
        if (_relPath)
            set(FILE_SRC "${_relPath}/${_src}")
        else()
            set(FILE_SRC "${_src}")
        endif()

        # Set test name
        string(REGEX REPLACE ".vhd" ""  TEST_NAME "${FILE_SRC}")
        string(REGEX REPLACE "/"    "." TEST_NAME "${TEST_NAME}")

        # Set entity name
        string(REGEX REPLACE ".vhd" ""  ENTITY_NAME "${_src}")

        # Set trace path
        file(RELATIVE_PATH TEST_REL_PATH "${CMAKE_SOURCE_DIR}/test" "${CMAKE_CURRENT_SOURCE_DIR}")
        set(TRACE_PATH "${CMAKE_BINARY_DIR}/trace/${TEST_REL_PATH}")
        file(MAKE_DIRECTORY ${TRACE_PATH})
        set(TRACE_PATH "${TRACE_PATH}/${ENTITY_NAME}.ghw")

        # Add test
        add_custom_target("${TEST_NAME}" COMMAND ghdl -m --workdir=${CMAKE_BINARY_DIR} ${ENTITY_NAME} DEPENDS index)
        list (APPEND VHDL_SOURCES "${CMAKE_SOURCE_DIR}/${FILE_SRC}")
        add_test(NAME "${TEST_NAME}" COMMAND ghdl -r --workdir=${CMAKE_BINARY_DIR} ${ENTITY_NAME} --wave=${TRACE_PATH} WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR})

        # Add this test as a dependency for 'make check'
        add_dependencies(check "${TEST_NAME}")
        message("-- Adding VHDL Test: ${CMAKE_SOURCE_DIR}/${FILE_SRC}")
    endforeach()
    if (_relPath)
        # Propagate to parent directory
        set (VHDL_SOURCES ${VHDL_SOURCES} PARENT_SCOPE)
    endif()
endmacro()
