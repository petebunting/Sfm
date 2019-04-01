usage() { echo "Usage: $0 [-c csv file] [-s subset csv]" 1>&2; exit 1; }

while getopts ":c:s:" o; do
    case "${o}" in
        c)
            csv=${OPTARG}

            ;;
        s)
            sub=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

if [ -z "${csv}" ] || [ -z "${sub}" ]; then
    usage
fi

echo "csv = ${csv}"
echo "sub = ${sub}"
